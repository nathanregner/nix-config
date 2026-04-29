-- TODO: auto-show output panel on failure
-- TODO: auto-show clear on run (watch)

-- Neotest

---@module "lazy"
---@type LazySpec
return {
  "nvim-neotest/neotest",
  -- https://github.com/nvim-neotest/neotest/issues/531
  commit = "52fca6717ef972113ddd6ca223e30ad0abb2800c",
  dependencies = {
    "nvim-neotest/nvim-nio",
    "nvim-lua/plenary.nvim",
    "nvim-treesitter/nvim-treesitter",
    "nvim-treesitter/nvim-treesitter-textobjects",
    -- Adapters
    "nvim-neotest/neotest-jest",
  },
  lazy = true,
  keys = {
    { "<leader>ts", function() require("neotest").summary.toggle() end, "Test summary" },
    { "<leader>to", function() require("neotest").output_panel.toggle() end, "Test output" },
    {
      "<localleader>tt",
      function()
        local neotest = require("neotest")
        neotest.output_panel.clear()
        neotest.run.run()
        neotest.summary.open()
        -- TODO: if `output_panel` not open in current window, show output
      end,
      "Test This",
    },
    {
      "<localleader>tl",
      function()
        local neotest = require("neotest")
        neotest.output_panel.clear()
      end,
      "Test Previous",
    },
    {
      "<localleader>tp",
      function()
        local neotest = require("neotest")
        neotest.output_panel.clear()
        neotest.run.run("last")
        neotest.summary.open()
      end,
      "Test Previous",
    },
    {
      "<localleader>tf",
      function()
        local neotest = require("neotest")
        neotest.run.run(vim.fn.expand("%"))
        neotest.summary.open()
      end,
      "Test File",
    },
    {
      "<leader>tq",
      function()
        local neotest = require("neotest")
        neotest.run.stop()
        neotest.watch.stop()
        neotest.summary.close()
        neotest.output_panel.close()
      end,
      "Test Quit",
    },
    {
      "<localleader>twt",
      function()
        local neotest = require("neotest")
        neotest.watch.watch()
        neotest.summary.open()
      end,
      "Test Watch This",
    },
    {
      "<localleader>to",
      function()
        local neotest = require("neotest")
        neotest.output.open({ short = true, enter = true, auto_close = true })
      end,
      "Test Quit",
    },
    { "<leader>twq", function() require("neotest").watch.stop() end, "Test Watch Quit" },
    { "<leader>tr", function() require("neotest").output_panel.clear() end, "Test Reset logs" },
  },
  config = function()
    local neotest = require("neotest")
    ---@diagnostic disable-next-line: missing-fields
    neotest.setup({
      ---@diagnostic disable-next-line: missing-fields
      discovery = {
        -- enabled = false,
      },
      adapters = {
        require("rustaceanvim.neotest"),
        require("neotest-jest")({
          -- jestCommand = "npx jest --",
          jest_test_discovery = true,
          -- isTestFile = function(file_path)
          --   return file_path:match("__tests__/") or file_path:match("%.test%.[jt]sx?$")
          -- end,
        }),
        -- require("neotest-vitest"),
      },
      diagnostic = {
        enabled = true,
        severity = vim.diagnostic.severity.WARN,
      },
      ---@diagnostic disable-next-line: missing-fields
      output = {
        open_on_run = false,
        enter = true,
      },
    })
  end,
  init = function()
    local next, prev = make_repeatable_move_pair(
      function() require("neotest").jump.next({ status = "failed" }) end,
      function() require("neotest").jump.prev({ status = "failed" }) end
    )
    vim.keymap.set("n", "]n", next, { desc = "Next failed test" })
    vim.keymap.set("n", "[n", prev, { desc = "Previous failed test" })
  end,
}
