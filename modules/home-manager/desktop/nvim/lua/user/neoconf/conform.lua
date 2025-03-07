--- @class ConformSettings
local defaults = {
  enabled = true,
  filetypes = {},
}

--[[ - @field enabled boolean
- @field filetypes { [string]: boolean } ]]

local settings = nil

local M = {
  register = function()
    -- https://github.com/folke/neoconf.nvim/blob/fbe717664a732ab9e62737216bd3d0b6d9f84dbf/lua/neoconf/plugins/lspconfig.lua
    require("neoconf.plugins").register({
      name = "conform",
      on_schema = function(schema)
        schema:import("conform", defaults)
        local properties = {}
        local filetypes = vim.fn.getcompletion("", "filetype")
        for _, value in ipairs(filetypes) do
          properties[value] = { type = "boolean" }
        end
        schema:set("conform.filetypes", {
          type = "object",
          properties = properties,
        })
      end,
      on_update = function() settings = require("neoconf").get("conform", defaults) end,
    })
  end,
  --- @return ConformSettings
  settings = function()
    if not settings then settings = require("neoconf").get("conform", defaults) end
    return settings
  end,
}

return M
