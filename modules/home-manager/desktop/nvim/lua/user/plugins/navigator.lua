---@module "lazy"
---@type LazySpec
return {
  "numToStr/Navigator.nvim",
  opts = {
    -- Save modified buffer(s) when moving to mux
    auto_save = "all",
  },
  init = function()
    vim.keymap.set({ "n", "t" }, "<C-h>", "<CMD>NavigatorLeft<CR>")
    vim.keymap.set({ "n", "t" }, "<C-l>", "<CMD>NavigatorRight<CR>")
    vim.keymap.set({ "n", "t" }, "<C-k>", "<CMD>NavigatorUp<CR>")
    vim.keymap.set({ "n", "t" }, "<C-j>", "<CMD>NavigatorDown<CR>")
  end,
}
