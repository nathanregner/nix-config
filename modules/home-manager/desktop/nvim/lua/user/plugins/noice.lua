---@module "lazy"
---@type LazySpec
return {
  "folke/noice.nvim",
  priority = 999,
  lazy = false,
  dependencies = {
    "MunifTanjim/nui.nvim",
  },
  event = "VeryLazy",
  ---@type NoiceConfig
  opts = {
    cmdline = { enabled = false },
    messages = { enabled = false },
    routes = {
      {
        filter = {
          any = {
            --- jdtls
            { event = "lsp", kind = "progress", find = "Validate documents" },
            { event = "lsp", kind = "progress", find = "Publish Diagnostics" },
          },
        },
        opts = { skip = true },
      },
    },
  },
}
