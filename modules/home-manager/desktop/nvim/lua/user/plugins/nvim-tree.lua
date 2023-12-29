-- disable netrw
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

return {
  "nvim-tree/nvim-tree.lua",
  lazy = false,
  dependencies = {
    "nvim-tree/nvim-web-devicons",
  },
  keys = {
    {
      "<leader>ft",
      function()
        require("nvim-tree.api").tree.open({ find_file = true })
      end,
      desc = "[F]ind file in [T]ree",
    },
  },
  opts = {},
}
