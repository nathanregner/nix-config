---@module "lazy"
---@type LazySpec
return {
  "git@github.com:nathanregner/diffview.nvim",
  cmd = { "DiffviewOpen", "DiffviewFileHistory" },
  keys = function()
    local git = require("user.git")
    return {
      { "<leader>dd", "<cmd>DiffviewOpen<cr>", desc = "Diffview Open" },
      {
        "<leader>dm",
        function()
          vim.cmd({
            cmd = "DiffviewOpen",
            args = {
              --- could use main..., but that won't diff with the working tree
              git.merge_base(git.default_branch()),
            },
          })
        end,
        desc = "Diffview Open ma{in,aster}",
      },
      { "<leader>du", "<cmd>DiffviewOpen @{u}<cr>", desc = "Diffview Open upstream" },
    }
  end,
  opts = function()
    local actions = require("diffview.actions")

    local next_change, prev_change = make_repeatable_move_pair(actions.smart_next_change(), actions.smart_prev_change())

    local function focus_diff()
      local view = require("diffview.lib").get_current_view()
      if view and view.cur_layout then view.cur_layout:get_main_win():focus() end
    end

    return {
      keymaps = {
        view = {
          { "n", "]c", next_change, { desc = "Next change or next file" } },
          { "n", "[c", prev_change, { desc = "Prev change or prev file" } },
        },
        file_panel = {
          { "n", "]c", focus_diff, { desc = "Focus diff view" } },
          { "n", "[c", focus_diff, { desc = "Focus diff view" } },
        },
      },
    }
  end,
}
