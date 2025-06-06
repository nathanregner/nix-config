local config = require("nvim-surround.config")

require("nvim-surround").setup({
  surrounds = {
    -- ["t"] = {
    --   add = function()
    --     local user_input = config.get_input("Enter the HTML tag: ")
    --     if user_input then
    --       local element = user_input:match("^<?([^%s>]*)")
    --       local attributes = user_input:match("^<?[^%s>]*%s+(.-)>?$")
    --
    --       local open = attributes and element .. " " .. attributes or element
    --       local close = element
    --
    --       return { { "<" .. open .. ">" }, { "</" .. close .. ">" } }
    --     end
    --   end,
    --   find = function() return config.get_selection({ motion = "at" }) end,
    --   ---@type user_delete
    --   delete = function()
    --     vim.print("find outer")
    --     local selection = config.get_selection({
    --       query = {
    --         capture = "@tag.outer",
    --         type = "textobjects",
    --       },
    --     })
    --     vim.print(selection)
    --     if selection then return { selection } end
    --   end,
    --   change = {
    --     target = "^<([^%s<>]*)().-([^/]*)()>$",
    --     replacement = function()
    --       local user_input = config.get_input("Enter the HTML tag: ")
    --       if user_input then
    --         local element = user_input:match("^<?([^%s>]*)")
    --         local attributes = user_input:match("^<?[^%s>]*%s+(.-)>?$")
    --
    --         local open = attributes and element .. " " .. attributes or element
    --         local close = element
    --
    --         return { { open }, { close } }
    --       end
    --     end,
    --   },
    -- },
  },
})
