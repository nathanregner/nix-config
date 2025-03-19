local config = require("nvim-surround.config")

require("nvim-surround").setup({
  surrounds = {
    ["t"] = {
      add = function()
        local user_input = config.get_input("Enter the HTML tag: ")
        if user_input then
          local element = user_input:match("^<?([^%s>]*)")
          local attributes = user_input:match("^<?[^%s>]*%s+(.-)>?$")

          local open = attributes and element .. " " .. attributes or element
          local close = element

          return { { "<" .. open .. ">" }, { "</" .. close .. ">" } }
        end
      end,
      find = function() return config.get_selection({ motion = "at" }) end,
      ---@type user_delete
      delete = function()
        vim.print("find outer")
        local selection = config.get_selection({
          query = {
            capture = "@tag.outer",
            type = "textobjects",
          },
        })
        vim.print(selection)
        if selection then return { selection } end
      end,
      change = {
        target = "^<([^%s<>]*)().-([^/]*)()>$",
        replacement = function()
          local user_input = config.get_input("Enter the HTML tag: ")
          if user_input then
            local element = user_input:match("^<?([^%s>]*)")
            local attributes = user_input:match("^<?[^%s>]*%s+(.-)>?$")

            local open = attributes and element .. " " .. attributes or element
            local close = element

            return { { open }, { close } }
          end
        end,
      },
    },
  },
})

local ts_query = require("nvim-treesitter.query")
local ts_utils = require("nvim-treesitter.ts_utils")
local utils = require("nvim-surround.utils")

---@return user_delete
function get_selection(bufnr, capture)
  local matches = ts_query.get_capture_matches_recursively(bufnr, capture, "textobjects")
  local selections = {}
  for _, match in ipairs(matches) do
    local start = match.start
    local end_ = match.end_
    if start and start.node and end_ and end_.node then
      local range = { ts_utils.get_vim_range({ match.node:range() }) }
      table.insert(selections, {
        left = {
          first_pos = { range[1], range[2] },
          node = start.node,
        },
        right = {
          last_pos = { range[3], range[4] },
          node = end_.node,
        },
      })
    end
  end
  local selection = utils.filter_selections_list(selections)
  if selection then
    -- return selection.left.node, selection.right.node
  end
end
