---@module "lazy"
---@type LazySpec
return {
  "esmuellert/codediff.nvim",
  cmd = "CodeDiff",
  version = "*",
  keys = function()
    local git = require("user.git")
    return {
      { "<leader>dd", "<cmd>CodeDiff<cr>", desc = "CodeDiff Open" },
      {
        "<leader>dm",
        function()
          vim.cmd({
            cmd = "CodeDiff",
            args = {
              --- could use main..., but that won't diff with the working tree
              git.merge_base(git.default_branch()),
            },
          })
        end,
        desc = "CodeDiff Open ma{in,aster}",
      },
      { "<leader>du", "<cmd>CodeDiff @{u}<cr>", desc = "CodeDiff Open upstream" },
    }
  end,
  -- opts = function()
  --   local actions = require("CodeDiff.actions")
  --
  --   local next_change, prev_change = make_repeatable_move_pair(actions.smart_next_change(), actions.smart_prev_change())
  --
  --   local function focus_diff()
  --     local view = require("CodeDiff.lib").get_current_view()
  --     if view and view.cur_layout then view.cur_layout:get_main_win():focus() end
  --   end
  --
  --   return {
  --     keymaps = {
  --       view = {
  --         { "n", "]c", next_change, { desc = "Next change or next file" } },
  --         { "n", "[c", prev_change, { desc = "Prev change or prev file" } },
  --       },
  --       file_panel = {
  --         { "n", "]c", focus_diff, { desc = "Focus diff view" } },
  --         { "n", "[c", focus_diff, { desc = "Focus diff view" } },
  --       },
  --     },
  --   }
  -- end,
  opts = {
    diff = { compute_moves = true },
    keymaps = {
      view = {
        diff_get = "hg",
        diff_put = "hp",
        next_file = "<tab>",
        prev_file = "<s-tab>",
        quit = "<C-c>",
        toggle_stage = "hs",
      },
    },
  },
}
