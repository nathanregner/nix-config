---@module "lazy"
---@type LazySpec
return {
  "neovim/nvim-lspconfig",
  dependencies = {
    "artemave/workspace-diagnostics.nvim",
    "folke/neoconf.nvim",
    "yioneko/nvim-vtsls",
  },
  config = function() require("user.lsp") end,
}
