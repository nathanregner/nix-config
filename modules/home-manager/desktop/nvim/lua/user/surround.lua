vim.notify("setuppppp")
local config = require("nvim-surround.config")
local ts_query = require("nvim-treesitter.query")
local ts_utils = require("nvim-treesitter.ts_utils")
local utils = require("nvim-surround.utils")

---@return user_delete
local get_selection = function(bufnr, capture)
  local matches = ts_query.get_capture_matches_recursively(bufnr, capture, "textobjects")
  local selections = {}
  for _, match in ipairs(matches) do
    local start = match.start
    local end_ = match.end_
    if start and start.node and end_ and end_.node then
      ---@param node TSNode
      function node_to_selection(node)
        local range = { ts_utils.get_vim_range({ node:range() }) }
        return {
          first_pos = { range[1], range[2] },
          last_pos = { range[3], range[4] },
        }
      end
      -- local range = { ts_utils.get_vim_range({ match.node:range() }) }
      table.insert(selections, {
        left = node_to_selection(start.node),
        right = node_to_selection(end_.node),
      })
    end
  end
  local selection = utils.filter_selections_list(selections)
  return selection
end

-- require("nvim-surround").setup({
--   surrounds = {
--     ["t"] = {
--       -- add = function()
--       --   local user_input = config.get_input("Enter the HTML tag: ")
--       --   if user_input then
--       --     local element = user_input:match("^<?([^%s>]*)")
--       --     local attributes = user_input:match("^<?[^%s>]*%s+(.-)>?$")
--       --
--       --     local open = attributes and element .. " " .. attributes or element
--       --     local close = element
--       --
--       --     return { { "<" .. open .. ">" }, { "</" .. close .. ">" } }
--       --   end
--       -- end,
--       -- find = function() return config.get_selection({ motion = "at" }) end,
--       delete = function()
--         vim.print("find outer")
--         local selection = get_selection(0, "@tag.outer")
--         vim.print(selection)
--         return selection
--       end,
--       -- change = {
--       --   target = "^<([^%s<>]*)().-([^/]*)()>$",
--       --   replacement = function()
--       --     local user_input = config.get_input("Enter the HTML tag: ")
--       --     if user_input then
--       --       local element = user_input:match("^<?([^%s>]*)")
--       --       local attributes = user_input:match("^<?[^%s>]*%s+(.-)>?$")
--       --
--       --       local open = attributes and element .. " " .. attributes or element
--       --       local close = element
--       --
--       --       return { { open }, { close } }
--       --     end
--       --   end,
--       -- },
--     },
--   },
-- })
