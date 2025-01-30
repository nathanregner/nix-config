return {
  "olimorris/codecompanion.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-treesitter/nvim-treesitter",
  },
  opts = {
    -- Refer to: https://github.com/olimorris/codecompanion.nvim/blob/main/lua/codecompanion/config.lua
    strategies = {
      chat = { adapter = "ollama" },
      inline = { adapter = "ollama" },
    },
    opts = {
      log_level = "DEBUG",
    },
  },
}
