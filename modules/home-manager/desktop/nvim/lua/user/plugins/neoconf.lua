---@module "lazy"
---@type LazySpec
return {
  "folke/neoconf.nvim",
  opts = {
    plugins = {
      jsonls = {
        configured_servers_only = false,
      },
    },
  },
  config = function(opts)
    require("neoconf").setup(opts)
    require("user.neoconf.conform").register()
  end,
}
