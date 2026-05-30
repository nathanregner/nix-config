local initial_cwd = vim.fn.getcwd()

---@module "lazy"
---@type LazySpec
return {
  "stevearc/oil.nvim",
  dependencies = { { "nvim-tree/nvim-web-devicons", opts = {} } },
  lazy = false,
  keys = {
    { "-", function() require("oil").open() end },
  },
  opts = {
    keymaps = {
      ["<C-cr>"] = { "actions.select", opts = { vertical = true } },
      ["<C-h>"] = false,
      ["<C-l>"] = false,
      ["<C-p>"] = false,
      ["<C-s>"] = { "actions.select", opts = { horizontal = true } },
      ["<C-t>"] = { "actions.select", opts = { tab = true } },
      ["<k>"] = "actions.preview",

      ["<Esc>"] = function()
        local oil = require("oil")
        local was_modified = vim.bo.modified
        if was_modified then
          local choice = vim.fn.confirm("Save changes?", "Yes\nNo", 1)
          if choice == 1 then oil.save() end
        end
        oil.close()
      end,
      ["g-"] = {
        desc = "Navigate to the git root",
        callback = function()
          local oil = require("oil")
          local git = require("user.git")
          local cwd = oil.get_current_dir():gsub("/$", "")
          local git_root = git.root(cwd)
          if git_root == cwd then
            local parent_root = git.root(vim.fs.dirname(git_root))
            if parent_root and parent_root ~= git_root then oil.open(parent_root) end
          elseif git_root then
            oil.open(git_root)
          end
        end,
      },
      ["g^"] = {
        desc = "Navigate to the initial cwd (set on startup)",
        callback = function()
          local oil = require("oil")
          vim.notify(initial_cwd)
          oil.open(initial_cwd)
        end,
      },
      ["gd"] = {
        desc = "Toggle file detail view",
        callback = function()
          detail = not detail
          if detail then
            require("oil").set_columns({ "icon", "permissions", "size", "mtime" })
          else
            require("oil").set_columns({ "icon" })
          end
        end,
      },
    },
  },
}
