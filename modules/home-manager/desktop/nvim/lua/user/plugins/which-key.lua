---@module "lazy"
---@type LazySpec
return {
  "folke/which-key.nvim",
  event = "VeryLazy",
  config = function()
    ---@diagnostic disable-next-line: missing-fields
    require("which-key").setup({})
    require("which-key").add({
      { "<leader>c", group = "Code" },
      { "<leader>f", group = "Find" },
      { "<leader>g", group = "Git" },
      { "<leader>h", group = "Hunk" },
      { "<leader>r", group = "Rename" },
      { "<leader>w", group = "Workspace" },
    })
  end,
}
