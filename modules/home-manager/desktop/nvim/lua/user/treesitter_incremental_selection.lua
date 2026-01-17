local api = vim.api
local ts = vim.treesitter

local parsers = require("nvim-treesitter.parsers")

local query_cache = require("user.treesitter_caching").create_buffer_cache()

local EMPTY_ITER = function() end

local function get_buf_lang(bufnr)
  bufnr = bufnr or api.nvim_get_current_buf()

  local filetype = vim.bo[bufnr].filetype
  return ts.language.get_lang(filetype) or filetype
end

local function get_parser(bufnr, lang)
  bufnr = bufnr or api.nvim_get_current_buf()
  lang = lang or get_buf_lang(bufnr)

  if parsers[lang] then return ts.get_parser(bufnr, lang) end
end

---@param bufnr integer
---@param query_name string
---@param root TSNode
---@param root_lang string|nil
---@return Query|nil, QueryInfo|nil
local function prepare_query(bufnr, query_name, root, root_lang)
  local buf_lang = parsers.get_buf_lang(bufnr)

  if not buf_lang then return end

  local parser = get_parser(bufnr, buf_lang)
  if not parser then return end

  if not root then
    local first_tree = parser:trees()[1]

    if first_tree then root = first_tree:root() end
  end

  if not root then return end

  local range = { root:range() }

  if not root_lang then
    local lang_tree = parser:language_for_range(range)

    if lang_tree then root_lang = lang_tree:lang() end
  end

  if not root_lang then return end

  local query = get_query(root_lang, query_name)
  if not query then return end

  return query,
    {
      root = root,
      source = bufnr,
      start = range[1],
      -- The end row is exclusive so we need to add 1 to it.
      stop = range[3] + 1,
    }
end

---@param query Query
---@param bufnr integer
---@param start_row integer
---@param end_row integer
local function iter_prepared_matches(query, qnode, bufnr, start_row, end_row)
  -- A function that splits  a string on '.'
  ---@param to_split string
  ---@return string[]
  local function split(to_split)
    local t = {}
    for str in string.gmatch(to_split, "([^.]+)") do
      table.insert(t, str)
    end

    return t
  end

  local matches = query:iter_matches(qnode, bufnr, start_row, end_row, { all = false })

  local function iterator()
    local pattern, match, metadata = matches()
    if pattern ~= nil then
      local prepared_match = {}

      -- Extract capture names from each match
      for id, node in pairs(match) do
        local name = query.captures[id] -- name of the capture in the query
        if name ~= nil then
          local path = split(name .. ".node")
          insert_to_path(prepared_match, path, node)
          local metadata_path = split(name .. ".metadata")
          insert_to_path(prepared_match, metadata_path, metadata[id])
        end
      end

      -- Add some predicates for testing
      ---@type string[][] ( TODO: make pred type so this can be pred[])
      local preds = query.info.patterns[pattern]
      if preds then
        for _, pred in pairs(preds) do
          -- functions
          if pred[1] == "set!" and type(pred[2]) == "string" then
            insert_to_path(prepared_match, split(pred[2]), pred[3])
          end
          if pred[1] == "make-range!" and type(pred[2]) == "string" and #pred == 4 then
            insert_to_path(
              prepared_match,
              split(pred[2] .. ".node"),
              tsrange.TSRange.from_nodes(bufnr, match[pred[3]], match[pred[4]])
            )
          end
        end
      end

      return prepared_match
    end
  end
  return iterator
end

---Iterates matches from a query file.
---@param bufnr integer the buffer
---@param query_group string the query file to use
---@param root TSNode the root node
---@param root_lang? string the root node lang, if known
local function iter_group_results(bufnr, query_group, root, root_lang)
  local query, params = prepare_query(bufnr, query_group, root, root_lang)
  if not query then return EMPTY_ITER end
  assert(params)

  return iter_prepared_matches(query, params.root, params.source, params.start, params.stop)
end

local function collect_group_results(bufnr, query_group, root, lang)
  local matches = {}

  for prepared_match in iter_group_results(bufnr, query_group, root, lang) do
    table.insert(matches, prepared_match)
  end

  return matches
end

local function update_cached_matches(bufnr, changed_tick, query_group)
  query_cache.set(query_group, bufnr, {
    tick = changed_tick,
    cache = collect_group_results(bufnr, query_group) or {},
  })
end

---@param bufnr integer
---@param query_group string
---@return any
local function get_matches(bufnr, query_group)
  bufnr = bufnr or api.nvim_get_current_buf()
  local cached_local = query_cache.get(query_group, bufnr)
  if not cached_local or api.nvim_buf_get_changedtick(bufnr) > cached_local.tick then
    update_cached_matches(bufnr, api.nvim_buf_get_changedtick(bufnr), query_group)
  end

  return query_cache.get(query_group, bufnr).cache
end

---@param bufnr integer
---@return any
local function get_locals(bufnr) return get_matches(bufnr, "locals") end

local function get_scopes(bufnr)
  local locals = get_locals(bufnr)

  local scopes = {}

  for _, loc in ipairs(locals) do
    if loc["local"]["scope"] and loc["local"]["scope"].node then table.insert(scopes, loc["local"]["scope"].node) end
  end

  return scopes
end

---@param node TSNode
---@param bufnr? integer
---@param allow_scope? boolean
---@return TSNode|nil
local function containing_scope(node, bufnr, allow_scope)
  local bufnr = bufnr or api.nvim_get_current_buf()
  local allow_scope = allow_scope == nil or allow_scope == true

  local scopes = get_scopes(bufnr)
  if not node or not scopes then return end

  local iter_node = node

  while iter_node ~= nil and not vim.tbl_contains(scopes, iter_node) do
    iter_node = iter_node:parent()
  end

  return iter_node or (allow_scope and node or nil)
end

local function get_root_for_position(line, col, root_lang_tree)
  if not root_lang_tree then
    if not parsers.has_parser() then return end

    root_lang_tree = get_parser()
  end

  local lang_tree = root_lang_tree:language_for_range({ line, col, line, col })

  while true do
    for _, tree in pairs(lang_tree:trees()) do
      local root = tree:root()

      if root and ts.is_in_node_range(root, line, col) then return root, tree, lang_tree end
    end

    if lang_tree == root_lang_tree then break end

    -- This case can happen when the cursor is at the start of a line that ends a injected region,
    -- e.g., the first `]` in the following lua code:
    -- ```
    -- vim.cmd[[
    -- ]]
    -- ```
    lang_tree = lang_tree:parent() -- NOTE: parent() method is private
  end

  -- This isn't a likely scenario, since the position must belong to a tree somewhere.
  return nil, nil, lang_tree
end

local function get_node_at_cursor(winnr, ignore_injected_langs)
  winnr = winnr or 0
  local cursor = api.nvim_win_get_cursor(winnr)
  local cursor_range = { cursor[1] - 1, cursor[2] }

  local buf = vim.api.nvim_win_get_buf(winnr)
  local root_lang_tree = get_parser(buf)
  if not root_lang_tree then return end

  local root ---@type TSNode|nil
  if ignore_injected_langs then
    for _, tree in pairs(root_lang_tree:trees()) do
      local tree_root = tree:root()
      if tree_root and ts.is_in_node_range(tree_root, cursor_range[1], cursor_range[2]) then
        root = tree_root
        break
      end
    end
  else
    root = get_root_for_position(cursor_range[1], cursor_range[2], root_lang_tree)
  end

  if not root then return end

  return root:named_descendant_for_range(cursor_range[1], cursor_range[2], cursor_range[1], cursor_range[2])
end

-- Get a compatible vim range (1 index based) from a TS node range.
--
-- TS nodes start with 0 and the end col is ending exclusive.
-- They also treat a EOF/EOL char as a char ending in the first
-- col of the next row.
---comment
---@param range integer[]
---@param buf integer|nil
---@return integer, integer, integer, integer
local function get_vim_range(range, buf)
  ---@type integer, integer, integer, integer
  local srow, scol, erow, ecol = unpack(range)
  srow = srow + 1
  scol = scol + 1
  erow = erow + 1

  if ecol == 0 then
    -- Use the value of the last col of the previous row instead.
    erow = erow - 1
    if not buf or buf == 0 then
      ecol = vim.fn.col({ erow, "$" }) - 1
    else
      ecol = #api.nvim_buf_get_lines(buf, erow - 1, erow, false)[1]
    end
    ecol = math.max(ecol, 1)
  end
  return srow, scol, erow, ecol
end

-- Set visual selection to node
-- @param selection_mode One of "charwise" (default) or "v", "linewise" or "V",
--   "blockwise" or "<C-v>" (as a string with 5 characters or a single character)
local function update_selection(buf, node, selection_mode)
  local start_row, start_col, end_row, end_col = get_vim_range({ ts.get_node_range(node) }, buf)

  local v_table = { charwise = "v", linewise = "V", blockwise = "<C-v>" }
  selection_mode = selection_mode or "charwise"

  -- Normalise selection_mode
  if vim.tbl_contains(vim.tbl_keys(v_table), selection_mode) then selection_mode = v_table[selection_mode] end

  -- enter visual mode if normal or operator-pending (no) mode
  -- Why? According to https://learnvimscriptthehardway.stevelosh.com/chapters/15.html
  --   If your operator-pending mapping ends with some text visually selected, Vim will operate on that text.
  --   Otherwise, Vim will operate on the text between the original cursor position and the new position.
  local mode = api.nvim_get_mode()
  if mode.mode ~= selection_mode then
    -- Call to `nvim_replace_termcodes()` is needed for sending appropriate command to enter blockwise mode
    selection_mode = vim.api.nvim_replace_termcodes(selection_mode, true, true, true)
    api.nvim_cmd({ cmd = "normal", bang = true, args = { selection_mode } }, {})
  end

  api.nvim_win_set_cursor(0, { start_row, start_col - 1 })
  vim.cmd("normal! o")
  api.nvim_win_set_cursor(0, { end_row, end_col - 1 })
end

local M = {}

---@type table<integer, table<TSNode|nil>>
local selections = {}

function M.init_selection()
  local buf = api.nvim_get_current_buf()
  get_parser():parse({ vim.fn.line("w0") - 1, vim.fn.line("w$") })
  local node = get_node_at_cursor()
  selections[buf] = { [1] = node }
  update_selection(buf, node)
end

-- Get the range of the current visual selection.
--
-- The range starts with 1 and the ending is inclusive.
---@return integer, integer, integer, integer
local function visual_selection_range()
  local _, csrow, cscol, _ = unpack(vim.fn.getpos("v")) ---@type integer, integer, integer, integer
  local _, cerow, cecol, _ = unpack(vim.fn.getpos(".")) ---@type integer, integer, integer, integer

  local start_row, start_col, end_row, end_col ---@type integer, integer, integer, integer

  if csrow < cerow or (csrow == cerow and cscol <= cecol) then
    start_row = csrow
    start_col = cscol
    end_row = cerow
    end_col = cecol
  else
    start_row = cerow
    start_col = cecol
    end_row = csrow
    end_col = cscol
  end

  return start_row, start_col, end_row, end_col
end

---@param node TSNode
---@return boolean
local function range_matches(node)
  local csrow, cscol, cerow, cecol = visual_selection_range()
  local srow, scol, erow, ecol = get_vim_range({ node:range() })
  return srow == csrow and scol == cscol and erow == cerow and ecol == cecol
end

---@param get_parent fun(node: TSNode): TSNode|nil
---@return fun():nil
local function select_incremental(get_parent)
  return function()
    local buf = api.nvim_get_current_buf()
    local nodes = selections[buf]

    local csrow, cscol, cerow, cecol = visual_selection_range()
    -- Initialize incremental selection with current selection
    if not nodes or #nodes == 0 or not range_matches(nodes[#nodes]) then
      local parser = get_parser()
      parser:parse({ vim.fn.line("w0") - 1, vim.fn.line("w$") })
      local node = parser:named_node_for_range(
        { csrow - 1, cscol - 1, cerow - 1, cecol },
        { ignore_injections = false }
      )
      update_selection(buf, node)
      if nodes and #nodes > 0 then
        table.insert(selections[buf], node)
      else
        selections[buf] = { [1] = node }
      end
      return
    end

    -- Find a node that changes the current selection.
    local node = nodes[#nodes] ---@type TSNode
    while true do
      local parent = get_parent(node)
      if not parent or parent == node then
        -- Keep searching in the parent tree
        local root_parser = get_parser()
        root_parser:parse({ vim.fn.line("w0") - 1, vim.fn.line("w$") })
        local current_parser = root_parser:language_for_range({ csrow - 1, cscol - 1, cerow - 1, cecol })
        if root_parser == current_parser then
          node = root_parser:named_node_for_range({ csrow - 1, cscol - 1, cerow - 1, cecol })
          update_selection(buf, node)
          return
        end
        -- NOTE: parent() method is private
        local parent_parser = current_parser:parent()
        parent = parent_parser:named_node_for_range({ csrow - 1, cscol - 1, cerow - 1, cecol })
      end
      node = parent
      local srow, scol, erow, ecol = get_vim_range({ node:range() })
      local same_range = (srow == csrow and scol == cscol and erow == cerow and ecol == cecol)
      if not same_range then
        table.insert(selections[buf], node)
        if node ~= nodes[#nodes] then table.insert(nodes, node) end
        update_selection(buf, node)
        return
      end
    end
  end
end

M.node_incremental = select_incremental(function(node) return node:parent() or node end)

M.scope_incremental = select_incremental(function(node)
  -- local lang = parsers.get_buf_lang()
  -- if queries.has_locals(lang) then
  return containing_scope(node:parent() or node)
  -- else
  --   return node
  -- end
end)

function M.node_decremental()
  local buf = api.nvim_get_current_buf()
  local nodes = selections[buf]
  if not nodes or #nodes < 2 then return end

  table.remove(selections[buf])
  local node = nodes[#nodes] ---@type TSNode
  update_selection(buf, node)
end

local FUNCTION_DESCRIPTIONS = {
  init_selection = "Start selecting nodes with nvim-treesitter",
  node_incremental = "Increment selection to named node",
  scope_incremental = "Increment selection to surrounding scope",
  node_decremental = "Shrink selection to previous named node",
}

local config = {
  keymaps = {
    node_incremental = "v",
    node_decremental = "V",
  },
}

---@param bufnr integer
function M.attach(bufnr)
  -- local config = configs.get_module("incremental_selection")
  for funcname, mapping in pairs(config.keymaps) do
    if mapping then
      local mode = funcname == "init_selection" and "n" or "x"
      local rhs = M[funcname] ---@type function

      -- if not rhs then
      --   vim.notify("Unknown keybinding: " .. funcname .. debug.traceback(), vim.log.levels.ERROR)
      -- else
      vim.keymap.set(mode, mapping, rhs, { buffer = bufnr, silent = true, desc = FUNCTION_DESCRIPTIONS[funcname] })
      -- end
    end
  end
end

function M.detach(bufnr)
  -- local config = configs.get_module("incremental_selection")
  for f, mapping in pairs(config.keymaps) do
    if mapping then
      local mode = f == "init_selection" and "n" or "x"
      vim.keymap.del(mode, mapping, { buffer = bufnr })
      -- local ok, err = pcall(vim.keymap.del, mode, mapping, { buffer = bufnr })
      -- if not ok then utils.notify(string.format('%s "%s" for mode %s', err, mapping, mode), vim.log.levels.ERROR) end
    end
  end
end

return M
