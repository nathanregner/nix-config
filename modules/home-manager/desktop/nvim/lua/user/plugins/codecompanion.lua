return {
  "olimorris/codecompanion.nvim",
  opts = {
    strategies = {
      chat = { adapter = "ollama" },
      inline = { adapter = "ollama" },
      cmd = { adapter = "ollama" },
    },
    logging_level = "DEBUG",
  },
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-treesitter/nvim-treesitter",
  },
}
