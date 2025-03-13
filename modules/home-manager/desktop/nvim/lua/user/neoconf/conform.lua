--- @class ConformSettings
--- @field filetypes { [string]: boolean } ]]
--- @field formatters { [string]: boolean } ]]
local defaults = {
  enabled = true,
  filetypes = {},
  formatters = {},
}

local settings = nil

local M = {
  register = function()
    -- https://github.com/folke/neoconf.nvim/blob/fbe717664a732ab9e62737216bd3d0b6d9f84dbf/lua/neoconf/plugins/lspconfig.lua
    require("neoconf.plugins").register({
      name = "conform",
      on_schema = function(schema)
        schema:import("conform", defaults)

        local filetypes = {}
        for _, name in ipairs(vim.fn.getcompletion("", "filetype")) do
          filetypes[name] = { type = "boolean" }
        end
        schema:set("conform.filetypes", { type = "object", properties = filetypes })

        local formatters = {}
        for _, formatter in ipairs(require("conform").list_all_formatters()) do
          formatters[formatter.name] = { type = "boolean" }
        end

        schema:set("conform.formatters", { type = "object", properties = formatters })
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
