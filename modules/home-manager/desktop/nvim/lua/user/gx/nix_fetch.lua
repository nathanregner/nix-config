local M = {}

-- Simple query to find fetchFromGitHub calls
local query_str = [[
  (apply_expression
    function: (_) @_func
    argument: (attrset_expression) @attrs) @fetch_call
  (#match? @_func "(^|\\.)fetchFromGitHub$")
]]

--- Extract string value from a string_expression node (only if no interpolation)
---@param node TSNode
---@param bufnr number
---@return string|nil
local function get_simple_string(node, bufnr)
  if node:type() ~= "string_expression" then return nil end

  local has_interpolation = false
  local value = nil

  for child in node:iter_children() do
    if child:type() == "interpolation" then
      has_interpolation = true
      break
    elseif child:type() == "string_fragment" then
      value = vim.treesitter.get_node_text(child, bufnr)
    end
  end

  if has_interpolation then return nil end
  return value
end

--- Extract attributes from an attrset_expression node
---@param attrs_node TSNode
---@param bufnr number
---@return table<string, string>
local function extract_attrs(attrs_node, bufnr)
  local attrs = {}

  for child in attrs_node:iter_children() do
    if child:type() == "binding_set" then
      for binding in child:iter_children() do
        if binding:type() == "binding" then
          local attr_name = nil
          local attr_value = nil

          for part in binding:iter_children() do
            if part:type() == "attrpath" then
              for ident in part:iter_children() do
                if ident:type() == "identifier" then
                  attr_name = vim.treesitter.get_node_text(ident, bufnr)
                  break
                end
              end
            elseif part:type() == "string_expression" then
              attr_value = get_simple_string(part, bufnr)
            end
          end

          if attr_name and attr_value then
            attrs[attr_name] = attr_value
          end
        end
      end
    end
  end

  return attrs
end

---@return string|nil
function M.handle()
  local bufnr = vim.api.nvim_get_current_buf()
  local cursor = vim.api.nvim_win_get_cursor(0)
  local row, col = cursor[1] - 1, cursor[2]

  local ok, parser = pcall(vim.treesitter.get_parser, bufnr, "nix")
  if not ok or not parser then return end

  local tree = parser:parse()[1]
  if not tree then return end

  local query = vim.treesitter.query.parse("nix", query_str)

  for _, match, _ in query:iter_matches(tree:root(), bufnr, 0, -1) do
    local fetch_call_node = nil
    local attrs_node = nil

    for id, nodes in pairs(match) do
      local name = query.captures[id]
      -- Handle both old (single node) and new (table of nodes) format
      local node = type(nodes) == "table" and nodes[1] or nodes
      if name == "fetch_call" then
        fetch_call_node = node
      elseif name == "attrs" then
        attrs_node = node
      end
    end

    if fetch_call_node and attrs_node then
      local sr, sc, er, ec = fetch_call_node:range()
      if row >= sr and row <= er and (row > sr or col >= sc) and (row < er or col <= ec) then
        local attrs = extract_attrs(attrs_node, bufnr)
        local owner = attrs["owner"]
        local repo = attrs["repo"]
        if owner and repo then
          local url = "https://github.com/" .. owner .. "/" .. repo
          local ref = attrs["tag"] or attrs["rev"]
          if ref then
            url = url .. "/tree/" .. ref
          end
          return url
        end
      end
    end
  end
end

return M
