local group = vim.api.nvim_create_augroup("baleia", { clear = true })
vim.api.nvim_create_autocmd({ "BufWinEnter" }, {
  pattern = { "*.log", "*.snap" },
  group = group,
  callback = function() vim.g.baleia.automatically(vim.api.nvim_get_current_buf()) end,
})

return {
  "m00qek/baleia.nvim",
  version = "*",
  config = function()
    vim.g.baleia = require("baleia").setup({})

    vim.api.nvim_create_user_command(
      "ColorizeAnsi",
      function() vim.g.baleia.once(vim.api.nvim_get_current_buf()) end,
      { bang = true }
    )

    vim.api.nvim_create_user_command("ColorizeAnsiLogs", vim.cmd.messages, { bang = true })
  end,
}
