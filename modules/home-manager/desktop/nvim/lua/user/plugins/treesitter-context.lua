---@module "lazy"
---@type LazySpec
return {
  "nvim-treesitter/nvim-treesitter-context",
  dependencies = { "nvim-treesitter/nvim-treesitter" },
  event = "VeryLazy",
  keys = function()
    return {
      {
        "[C",
        function() require("treesitter-context").go_to_context(vim.v.count1) end,
        silent = true,
      },
    }
  end,
  opts = {
    max_lines = 10,
    multiline_threshold = 1,
    -- mode = "topline",
  },
}
