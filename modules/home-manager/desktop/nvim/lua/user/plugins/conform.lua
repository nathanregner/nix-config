---@module "lazy"
---@type LazySpec
return {
  "stevearc/conform.nvim",
  event = "VeryLazy",
  dependencies = { "folke/neoconf.nvim" },
  config = function() require("user.conform") end,
}
