local cascade_enabled = true

---@module "lazy"
---@type LazySpec
return {
  "folke/trouble.nvim",
  dependencies = { "nvim-treesitter/nvim-treesitter-textobjects" },
  opts = {
    keys = {
      -- -- TODO: doesn't work quite right
      -- h = "fold_more",
      -- l = "fold_open",
      -- -- TODO:
      -- p = "parent_item",
      s = { -- replace default severity filter with cascading severity version
        action = function(view)
          cascade_enabled = not cascade_enabled

          local status = cascade_enabled and "enabled" or "disabled"
          local level = cascade_enabled and vim.log.levels.INFO or vim.log.levels.WARN
          vim.notify("Cascade filter **" .. status .. "**", level, { title = "Trouble" })

          view:refresh()
        end,
        desc = "Toggle cascade filter",
      },
    },
    modes = {
      symbols = {
        desc = "document symbols",
        mode = "lsp_document_symbols",
        focus = false,
        win = { position = "right", foldlevel = 1 },
      },
      diagnostic_cascade = {
        mode = "diagnostics", -- inherit from diagnostics mode
        filter = function(items)
          if not cascade_enabled then return items end

          local severity = vim.diagnostic.severity.HINT
          for _, item in ipairs(items) do
            severity = math.min(severity, item.severity)
          end

          -- If most severe level is INFO or HINT, show everything
          if severity >= vim.diagnostic.severity.INFO then return items end

          return vim.tbl_filter(function(item) return item.severity == severity end, items)
        end,
      },
    },
  }, -- for default options, refer to the configuration section for custom setup.
  cmd = "Trouble",
  init = function()
    ---@type any
    local trouble = require("trouble")
    local next, prev = make_repeatable_move_pair(
      function() trouble.next({ jump = true }) end,
      function() trouble.prev({ jump = true }) end
    )
    vim.keymap.set("n", "]x", next, { desc = "Trouble next" })
    vim.keymap.set("n", "[x", prev, { desc = "Trouble prev" })
    vim.keymap.set("n", "]X", function() trouble.last({ jump = true }) end, { desc = "Trouble last" })
    vim.keymap.set("n", "[X", function() trouble.first({ jump = true }) end, { desc = "Trouble first" })
  end,
  keys = {
    {
      "<leader>xx",
      "<cmd>Trouble diagnostic_cascade toggle<cr>",
      desc = "Diagnostics (Trouble)",
    },
    {
      "<leader>xX",
      "<cmd>Trouble diagnostic_cascade toggle filter.buf=0<cr>",
      desc = "Buffer Diagnostics (Trouble)",
    },
    {
      "<leader>cs",
      "<cmd>Trouble symbols toggle focus=false<cr>",
      desc = "Symbols (Trouble)",
    },
    {
      "<leader>cl",
      "<cmd>Trouble lsp toggle focus=false win.position=right<cr>",
      desc = "LSP Definitions / references / ... (Trouble)",
    },
    {
      "<leader>xL",
      "<cmd>Trouble loclist toggle<cr>",
      desc = "Location List (Trouble)",
    },
    {
      "<leader>xQ",
      "<cmd>Trouble qflist toggle<cr>",
      desc = "Quickfix List (Trouble)",
    },
  },
}
