local initial_cwd = vim.fn.getcwd()

---@module "lazy"
---@type LazySpec
return {
  "A7Lavinraj/fyler.nvim",
  dependencies = { { "nvim-tree/nvim-web-devicons", opts = {} } },
  -- branch = "stable", -- Use stable branch for production
  lazy = false, -- Necessary for `default_explorer` to work properly
  keys = {
    {
      "-",
      function()
        local buf_name = vim.api.nvim_buf_get_name(0) -- 0 refers to the current buffer
        local current_dir = vim.fs.dirname(buf_name)
        require("fyler").open({ dir = current_dir })
      end,
    },
  },
  opts = {
    -- TODO: jumplist
    -- TODO: ` should cd to the cwd
    -- TODO: open: replace current buffer, not new...
    default_explorer = true,
    integrations = {
      icon = "nvim_web_devicons",
    },
    views = {
      finder = {
        confirm_simple = true,
        mappings = {
          ["-"] = "GotoParent",
          ["."] = nil, -- GotoNode
          ["<Esc>"] = "CloseView",
          ["="] = nil, -- GotoCwd
          ["H"] = "GotoParent",
          ["_"] = "GotoCwd",
          ["`"] = "Select",
          ["q"] = nil, -- CloseView
        },
        win = {
          win_opts = {
            number = true,
            relativenumber = true,
            -- signcolumn = "yes",
          },
        },
      },
    },
  },
  config = function(_, opts)
    local mocha = require("catppuccin.palettes").get_palette("mocha")
    vim.api.nvim_set_hl(0, "FylerIndentMarker", { fg = mocha.overlay0 })
    require("fyler").setup(opts)
  end,
}
