---@module "lazy"
---@type LazySpec
return {
  "vim-test/vim-test",
  dependencies = {
    -- "skywind3000/asyncrun.vim",
    { "akinsho/toggleterm.nvim", opts = {} },
  },
  config = function() --
    local default = "toggleterm"
    vim.g["test#strategy"] = {
      file = default,
      nearest = default,
      suite = default,
    }
    vim.g["test#neovim#start_normal"] = 1
  end,
}
