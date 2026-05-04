---@module "lazy"
---@type LazySpec
return {
  "lewis6991/gitsigns.nvim",
  dependencies = { "nvim-treesitter/nvim-treesitter-textobjects" },
  opts = {
    on_attach = function(bufnr)
      local gs = require("gitsigns")

      local function map(mode, l, r, opts)
        opts = opts or {}
        opts.buffer = bufnr
        vim.keymap.set(mode, l, r, opts)
      end

      map("n", "<leader>hs", gs.stage_hunk, { desc = "[H]unk [S]tage" })
      map("n", "<leader>hr", gs.reset_hunk, { desc = "[H]unk [R]eset" })
      map(
        "v",
        "<leader>hs",
        function() gs.stage_hunk({ vim.fn.line("."), vim.fn.line("v") }) end,
        { desc = "[H]unk [S]tage" }
      )
      map(
        "v",
        "<leader>hr",
        function() gs.reset_hunk({ vim.fn.line("."), vim.fn.line("v") }) end,
        { desc = "[H]unk [R]eset" }
      )
      map("n", "<leader>hS", gs.stage_buffer, { desc = "[H]unk [S]tage buffer" })
      map("n", "<leader>hu", gs.undo_stage_hunk, { desc = "[H]unk [U]ndo stage" })
      map("n", "<leader>hU", gs.reset_buffer_index, { desc = "[H]unk [U]ndo stage" })

      map("n", "<leader>hR", gs.reset_buffer, { desc = "[H]unk [R]eset buffer" })
      map("n", "<leader>hP", gs.preview_hunk, { desc = "[H]unk [P]review" })

      map("n", "<leader>hb", function() gs.blame_line({ full = true }) end, { desc = "[H]unk [B]lame" })
      map("n", "<leader>hB", gs.toggle_current_line_blame, { desc = "Git [B]lame" })
      map("n", "<leader>hd", gs.diffthis, { desc = "[H]unk [D]iff" })
      map("n", "<leader>hD", function() gs.diffthis("~") end, { desc = "[H]unk [D]iff last commit" })
      map("n", "<leader>htd", gs.toggle_deleted, { desc = "[H]unk [T]oggle [D]eleted" })

      local ts_repeat_move = require("nvim-treesitter-textobjects.repeatable_move")

      local next_hunk = function()
        if vim.wo.diff then
          -- don't override the built-in and fugitive keymaps
          vim.api.nvim_feedkeys("]c", "n", false)
        else
          gs.nav_hunk("next")
        end
      end

      local prev_hunk = function()
        if vim.wo.diff then
          -- don't override the built-in and fugitive keymaps
          vim.api.nvim_feedkeys("[c", "n", false)
        else
          gs.nav_hunk("prev")
        end
      end

      local next_hunk_repeat, prev_hunk_repeat = make_repeatable_move_pair(next_hunk, prev_hunk)

      map({ "n", "v" }, "]c", next_hunk_repeat, { desc = "Jump to next hunk" })
      map({ "n", "v" }, "[c", prev_hunk_repeat, { desc = "Jump to previous hunk" })
    end,
  },
}
