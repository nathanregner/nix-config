return {
  "m00qek/baleia.nvim",
  config = function()
    vim.g.baleia = require("baleia").setup({})

    -- Command to colorize the current buffer
    vim.api.nvim_create_user_command(
      "AnsiColorize",
      function() vim.g.baleia.once(vim.api.nvim_get_current_buf()) end,
      { bang = true }
    )

    -- Command to show logs
    vim.api.nvim_create_user_command("AnsiLogs", vim.cmd.messages, { bang = true })
  end,
}
