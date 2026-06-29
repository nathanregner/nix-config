---@module "lazy"
---@type LazySpec
return {
  "vim-test/vim-test",
  dependencies = {
    "neomake/neomake",
    "skywind3000/asyncrun.vim",
    "tpope/vim-dispatch",
    { "akinsho/toggleterm.nvim", opts = {} },
  },
  config = function() --
    local default = "dispatch_background"
    vim.g["test#strategy"] = {
      file = default,
      nearest = default,
      suite = default,
    }
    vim.g["test#neovim#start_normal"] = 1
  end,
}
