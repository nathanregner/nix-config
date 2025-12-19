-- disable netrw
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

vim.opt.diffopt = "internal,filler,closeoff,indent-heuristic,linematch:60,algorithm:histogram"

vim.opt.wrap = false

vim.diagnostic.config({
  virtual_text = { current_line = true },
})

vim.opt.listchars = "tab:\\t,extends:>,precedes:<,trail:·"

-- auto-reload files when modified externally
-- https://unix.stackexchange.com/a/383044
vim.o.autoread = true
vim.api.nvim_create_autocmd({ "BufEnter", "CursorHold", "CursorHoldI", "FocusGained" }, {
  command = "if mode() !~ '\v(c|r.?|!|t)' && getcmdwintype() == '' | checktime | endif",
  pattern = { "*" },
})
vim.api.nvim_create_autocmd({ "FileChangedShellPost" }, {
  pattern = "*",
  callback = function()
    local filepath = vim.fn.expand("%:.")
    -- bail if file no longer exists (seems to trigger repeatedly)
    if vim.fn.filereadable(filepath) == 0 then return end
    vim.notify("Reloaded " .. filepath, vim.log.levels.INFO, {})
  end,
})

local function get_buffer_cwd()
  -- Use the current buffer's path as the starting point for the git search
  local current_file = vim.api.nvim_buf_get_name(0)
  current_file = string.gsub(current_file, "^oil://", "")
  local cwd = vim.fn.getcwd()
  -- If the buffer is not associated with a file, return nil
  if current_file == "" then
    current_dir = cwd
  else
    -- Extract the directory from the current file's path
    current_dir = vim.fn.fnamemodify(current_file, ":h")
  end
  return current_dir
end

local function get_git_root(current_dir)
  if current_dir == nil then current_dir = get_buffer_cwd() end

  -- Find the Git root directory from the current file's path
  local git_root = vim.fn.systemlist("git -C " .. vim.fn.escape(current_dir, " ") .. " rev-parse --show-toplevel")[1]
  if vim.v.shell_error ~= 0 then
    print("Not a git repository. Searching on current working directory")
    return nil
  end
  return git_root
end

vim.g.fugitive_legacy_commands = 0

local leet_arg = "leetcode.nvim"

---@param spec LazyPluginSpec
---@return LazyPluginSpec
function nix_spec(spec)
  local name = vim.fs.basename(spec[1])
  if name == nil then return spec end

  local nix = vim.g.nix[string.lower(name)]
  if nix == nil then
    vim.notify("Nix plugin not found " .. name, vim.log.levels.WARN)
    return spec
  end

  spec.dir = nix.dir
  spec.pin = true
  return spec
end

-- https://github.com/folke/lazy.nvim#-plugin-spec
require("lazy").setup({
  -- Git
  "tpope/vim-fugitive",
  "tpope/vim-rhubarb",

  -- replacement for ":w !sudo tee % > /dev/null" trick
  "lambdalisue/vim-suda",

  { -- Local (project-specific) config
    "klen/nvim-config-local",
    config = function()
      require("config-local").setup({
        config_files = { ".nvim.lua", ".nvimrc", ".exrc" },
        hashfile = vim.fn.stdpath("data") .. "/nvim-config-local",
      })
    end,
  },

  -- {
  --   "akinsho/git-conflict.nvim",
  --   version = "*",
  --   config = true,
  -- },

  -- https://github.com/sindrets/diffview.nvim#configuration
  {
    "sindrets/diffview.nvim",
    opts = {
      view = {
        merge_tool = {
          layout = "diff3_mixed",
        },
      },
    },
  },

  {
    "chentoast/marks.nvim",
    config = true,
  },

  {
    "mfussenegger/nvim-jdtls",
    ft = { "java" },
  },

  -- {
  --   "NeogitOrg/neogit",
  --   dependencies = {
  --     "nvim-lua/plenary.nvim", -- required
  --     "sindrets/diffview.nvim", -- optional - Diff integration
  --
  --     -- Only one of these is needed, not both.
  --     "nvim-telescope/telescope.nvim",
  --   },
  --   config = true,
  -- },

  -- Detect tabstop and shiftwidth automatically
  "tpope/vim-sleuth",

  -- Autoclose/Autoescape
  {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    config = function() require("user.pairs") end,
  },

  {
    "kevinhwang91/nvim-ufo",
    dependencies = { "kevinhwang91/promise-async" },
    lazy = false,
    config = function()
      local handler = function(virtText, lnum, endLnum, width, truncate)
        local newVirtText = {}
        local suffix = (" 󰁂 %d "):format(endLnum - lnum)
        local sufWidth = vim.fn.strdisplaywidth(suffix)
        local targetWidth = width - sufWidth
        local curWidth = 0
        for _, chunk in ipairs(virtText) do
          local chunkText = chunk[1]
          local chunkWidth = vim.fn.strdisplaywidth(chunkText)
          if targetWidth > curWidth + chunkWidth then
            table.insert(newVirtText, chunk)
          else
            chunkText = truncate(chunkText, targetWidth - curWidth)
            local hlGroup = chunk[2]
            table.insert(newVirtText, { chunkText, hlGroup })
            chunkWidth = vim.fn.strdisplaywidth(chunkText)
            -- str width returned from truncate() may less than 2nd argument, need padding
            if curWidth + chunkWidth < targetWidth then
              suffix = suffix .. (" "):rep(targetWidth - curWidth - chunkWidth)
            end
            break
          end
          curWidth = curWidth + chunkWidth
        end
        table.insert(newVirtText, { suffix, "MoreMsg" })
        return newVirtText
      end

      ---@diagnostic disable-next-line: missing-fields
      require("ufo").setup({
        open_fold_hl_timeout = 150,
        close_fold_kinds_for_ft = {
          default = { "imports", "comment" },
        },
        preview = {
          win_config = {
            winblend = 0,
          },
          mappings = {
            close = "q",
            switch = "K",
          },
        },
        fold_virt_text_handler = handler,
        ---@diagnostic disable-next-line: unused-local
        provider_selector = function(bufnr, filetype, buftype)
          -- vim.print({ _bufnr, _filetype, buftype })
          if buftype == "" or buftype == nil then return { "treesitter", "indent" } end
          return ""
        end,
      })
      vim.keymap.set("n", "zR", require("ufo").openAllFolds)
      vim.keymap.set("n", "zM", require("ufo").closeAllFolds)
      vim.keymap.set("n", "zr", require("ufo").openFoldsExceptKinds)
      vim.keymap.set("n", "zm", require("ufo").closeFoldsWith) -- closeAllFolds == closeFoldsWith(0)
      vim.keymap.set("n", "K", function()
        local winid = require("ufo").peekFoldedLinesUnderCursor()
        if not winid then vim.lsp.buf.hover() end
      end)
    end,
  },

  {
    "AndrewRadev/bufferize.vim",
    event = "CmdlineEnter",
    config = function() vim.api.nvim_create_user_command("Msgs", "Bufferize messages", { desc = "Bufferize messages" }) end,
  },

  { "towolf/vim-helm", ft = "helm" },

  {
    "folke/neoconf.nvim",
    opts = {
      plugins = {
        jsonls = {
          configured_servers_only = false,
        },
      },
    },
    config = function(opts)
      require("neoconf").setup(opts)
      require("user.neoconf.conform").register()
    end,
  },

  nix_spec({
    "L3MON4D3/LuaSnip",
    dependencies = {
      "rafamadriz/friendly-snippets",
      {
        "chrisgrieser/nvim-scissors",
        opts = {
          snippetDir = vim.fn.stdpath("config") .. "/snippets",
          jsonFormatter = { "prettierd", "dummy.json" },
        },
      },
    },
    config = function()
      require("luasnip").config.setup({ enable_autosnippets = true })
      require("luasnip.loaders.from_vscode").lazy_load()
      require("luasnip.loaders.from_vscode").lazy_load({
        paths = { vim.fn.stdpath("config") .. "/snippets" },
      })
      require("user.snippets")
    end,
  }),

  { -- LSP Configuration & Plugins
    "neovim/nvim-lspconfig",
    dependencies = {
      "artemave/workspace-diagnostics.nvim",
      "folke/neoconf.nvim",
      "yioneko/nvim-vtsls",
    },
    config = function() require("user.lsp") end,
  },

  {
    "folke/noice.nvim",
    priority = 999,
    lazy = false,
    dependencies = {
      "MunifTanjim/nui.nvim",
    },
    event = "VeryLazy",
    -- lazy = false,
    ---@type NoiceConfig
    opts = {
      cmdline = { enabled = false },
      messages = { enabled = false },
      routes = {
        {
          filter = {
            any = {
              --- jdtls
              { event = "lsp", kind = "progress", find = "Validate documents" },
              { event = "lsp", kind = "progress", find = "Publish Diagnostics" },
            },
          },
          opts = { skip = true },
        },
      },
    },
  },

  {
    "folke/lazydev.nvim",
    ft = "lua",
    dependencies = { "Bilal2453/luvit-meta", lazy = true }, -- optional `vim.uv` typings
    opts = {
      library = {
        { path = "luvit-meta/library", words = { "vim%.uv" } },
      },
    },
  },

  "b0o/schemastore.nvim",

  {
    "someone-stole-my-name/yaml-companion.nvim",
    requires = {
      { "neovim/nvim-lspconfig" },
      { "nvim-lua/plenary.nvim" },
      { "nvim-telescope/telescope.nvim" },
    },
  },

  { -- Autoformat
    "stevearc/conform.nvim",
    event = "VeryLazy",
    dependencies = { "folke/neoconf.nvim" },
    config = function() require("user.conform") end,
  },

  {
    "folke/noice.nvim",
    priority = 999,
    lazy = false,
    dependencies = {
      "MunifTanjim/nui.nvim",
    },
    event = "VeryLazy",
    -- lazy = false,
    opts = {
      cmdline = { enabled = false },
      messages = { enabled = false },
    },
  },

  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    config = function()
      ---@diagnostic disable-next-line: missing-fields
      require("which-key").setup({})
      require("which-key").add({
        { "<leader>c", group = "Code" },
        { "<leader>f", group = "Find" },
        { "<leader>g", group = "Git" },
        { "<leader>h", group = "Hunk" },
        { "<leader>r", group = "Rename" },
        { "<leader>w", group = "Workspace" },
      })
    end,
  },

  -- https://github.com/mbbill/undotree#configuration
  {
    "mbbill/undotree",
    keys = {
      { "<leader>fu", vim.cmd.UndotreeToggle, desc = "[F]ile [U]ndo Tree" },
    },
    config = function() vim.g.undotree_WindowLayout = 4 end,
  },

  { -- gitsigns
    "lewis6991/gitsigns.nvim",
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

        local ts_repeat_move = require("nvim-treesitter.textobjects.repeatable_move")

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

        local next_hunk_repeat, prev_hunk_repeat = ts_repeat_move.make_repeatable_move_pair(next_hunk, prev_hunk)

        map({ "n", "v" }, "]c", next_hunk_repeat, { desc = "Jump to next hunk" })
        map({ "n", "v" }, "[c", prev_hunk_repeat, { desc = "Jump to previous hunk" })
      end,
    },
  },

  -- {
  --   "brenoprata10/nvim-highlight-colors",
  --   opts = {},
  --   -- init = function() require("nvim-highlight-colors").turnOff() end,
  -- },

  { -- Theme
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000,
    opts = {
      flavour = "mocha",
      styles = {
        conditionals = {}, -- disable italics
      },
      highlight_overrides = {
        all = function(mocha)
          return {
            BlinkCmpKindText = { fg = mocha.subtext0 },
          }
        end,
      },
    },
    init = function() vim.cmd.colorscheme("catppuccin") end,
  },

  -- https://github.com/stevearc/dressing.nvim
  {
    "stevearc/dressing.nvim",
    opts = {},
  },

  {
    "nvim-lualine/lualine.nvim",
    opts = {
      options = {
        icons_enabled = false,
        theme = "catppuccin",
        component_separators = "|",
      },
      sections = {
        lualine_a = {
          "mode",
          function()
            local reg = vim.fn.reg_recording()
            if reg == "" then return "" end
            return "recording to " .. reg
          end,
        },
        lualine_b = { "diagnostics" },
        lualine_c = { { "filename", path = 1 } },
        lualine_x = { "encoding", "fileformat", "filetype" },
        lualine_y = { "progress", "searchcount" },
        lualine_z = { "location", "selectioncount" },
      },
    },
  },

  {
    {
      "antosha417/nvim-lsp-file-operations",
      dependencies = {
        "nvim-lua/plenary.nvim",
      },
      config = function() require("lsp-file-operations").setup() end,
    },
  },

  {
    "numToStr/Navigator.nvim",
    opts = {
      -- Save modified buffer(s) when moving to mux
      auto_save = "all",
    },
    init = function()
      vim.keymap.set({ "n", "t" }, "<C-h>", "<CMD>NavigatorLeft<CR>")
      vim.keymap.set({ "n", "t" }, "<C-l>", "<CMD>NavigatorRight<CR>")
      vim.keymap.set({ "n", "t" }, "<C-k>", "<CMD>NavigatorUp<CR>")
      vim.keymap.set({ "n", "t" }, "<C-j>", "<CMD>NavigatorDown<CR>")
    end,
  },

  "tpope/vim-repeat",

  {
    "max397574/better-escape.nvim",
    opts = {
      default_mappings = false,
      mappings = {
        i = { j = { k = "<Esc>" } },
        c = { j = { k = "<Esc>" } },
        t = { j = { k = "<C-\\><C-n>" } },
        v = { j = { k = "<Esc>" } },
        s = { j = { k = "<Esc>" } },
      },
    },
  },

  {
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
        ["g-"] = function()
          local oil = require("oil")
          local cwd = oil.get_current_dir()
          local git_root = get_git_root(cwd)
          if git_root == cwd then git_root = get_git_root(vim.fs.dirname(git_root)) end
          if git_root then oil.open(git_root) end
        end,
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
  },

  {
    "kylechui/nvim-surround",
    version = "*", -- Use for stability; omit to use `main` branch for the latest features
    event = "VeryLazy",
    opts = {},
  },

  { -- Comment.nvim
    "numToStr/Comment.nvim",
    dependencies = {
      { "JoosepAlviste/nvim-ts-context-commentstring", opts = { enable_autocmd = false } },
    },
    config = function()
      ---@diagnostic disable-next-line: missing-fields
      require("Comment").setup({
        pre_hook = require("ts_context_commentstring.integrations.comment_nvim").create_pre_hook(),
      })
    end,
  },

  -- TODO: auto-show output panel on failure
  -- TODO: auto-show clear on run (watch)
  { -- Neotest
    "nvim-neotest/neotest",
    -- https://github.com/nvim-neotest/neotest/issues/531
    commit = "52fca6717ef972113ddd6ca223e30ad0abb2800c",
    dependencies = {
      "nvim-neotest/nvim-nio",
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",
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
          -- neotest.output_panel.clear()
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
      local ts_repeat_move = require("nvim-treesitter.textobjects.repeatable_move")
      local next, prev = ts_repeat_move.make_repeatable_move_pair(
        function() require("neotest").jump.next({ status = "failed" }) end,
        function() require("neotest").jump.prev({ status = "failed" }) end
      )
      vim.keymap.set("n", "]n", next, { desc = "Next failed test" })
      vim.keymap.set("n", "[n", prev, { desc = "Previous failed test" })
    end,
  },

  { -- trouble.nvim
    "folke/trouble.nvim",
    opts = {
      keys = {
        -- -- TODO: doesn't work quite right
        -- h = "fold_more",
        -- l = "fold_open",
        -- -- TODO:
        -- p = "parent_item",
      },
      modes = {
        symbols = {
          desc = "document symbols",
          mode = "lsp_document_symbols",
          focus = false,
          win = { position = "right", foldlevel = 1 },
        },
      },
    }, -- for default options, refer to the configuration section for custom setup.
    cmd = "Trouble",
    init = function()
      ---@type any
      local trouble = require("trouble")
      local ts_repeat_move = require("nvim-treesitter.textobjects.repeatable_move")
      local next, prev = ts_repeat_move.make_repeatable_move_pair(
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
        "<cmd>Trouble diagnostics toggle<cr>",
        desc = "Diagnostics (Trouble)",
      },
      {
        "<leader>xX",
        "<cmd>Trouble diagnostics toggle filter.buf=0<cr>",
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
  },

  {
    "chrishrb/gx.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    keys = { { "gx", "<cmd>Browse<cr>", mode = { "n", "x" } } },
    cmd = { "Browse" },
    init = function() vim.g.netrw_nogx = 1 end,
    opts = {
      open_browser_app = vim.g.open_cmd,
      handlers = {
        plugin = true,
        github = true,
        package_json = true,
        search = {
          name = "search",
          handle = function(mode, line, opts)
            -- don't search unless selected
            if mode == "v" then return require("gx.handlers.search").handle(mode, line, opts) end
          end,
        },
        url = {
          name = "url",
          handle = function(mode, line, _)
            -- don't open URLs without a protocol
            local pattern = "(https?://[a-zA-Z%d_/%%%-%.~@\\+#=?&:]+)"
            return require("gx.helper").find(line, mode, pattern)
          end,
        },
        jira = {
          name = "jira",
          handle = function(mode, line, _)
            local jira_domain = vim.g.jira_domain
            if not jira_domain then return end

            local ticket = require("gx.helper").find(line, mode, "(%u+-%d+)")
            if ticket and #ticket < 20 then return "https://" .. jira_domain .. "/browse/" .. ticket end
          end,
        },
        flake_inputs = {
          name = "flake_inputs",
          -- filename = "flake.nix",
          handle = function(mode, line, _)
            -- https://nixos-and-flakes.thiscute.world/other-usage-of-flakes/inputs
            local owner_repo, ref = string.match(line, '"github:([^/]+/[^/]+/?)([^/]*)"')
            if owner_repo then
              local url = "https://github.com/" .. owner_repo
              if ref ~= "" then return url .. "tree/" .. ref end
              return url
            end
          end,
        },
        rust = {
          name = "rust",
          filename = "Cargo.toml",
          handle = function(mode, line, _)
            local crate = require("gx.helper").find(line, mode, "(%w+)%s-=%s")
            if crate then return "https://crates.io/crates/" .. crate end
          end,
        },
        fen = {
          handle = function(mode, line, _)
            -- local test = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"
            ---@param pattern vim.regex
            local function find(pattern)
              local i, j = pattern:match_str(line)
              if i and require("gx.helper").check_if_cursor_on_url(mode, i, j) then
                return string.sub(line, i + 1, j)
              end
            end

            local fen = find(vim.regex([[\v\c([pnbrqk1-8]+/){7}[pnbrqk1-8]+ [wb] [-qk]+ (-|(\w\d)) \d+ \d+]]))
            if fen then return "https://lichess.org/editor/" .. fen end
          end,
        },
      },
      handler_options = {
        search_engine = "google", -- you can select between google, bing, duckduckgo, ecosia and yandex
        select_for_search = false, -- if your cursor is e.g. on a link, the pattern for the link AND for the word will always match. This disables this behaviour for default so that the link is opened without the select option for the word AND link

        git_remotes = { "upstream", "origin" }, -- list of git remotes to search for git issue linking, in priority
        git_remote_push = true, -- use the push url for git issue linking,
      },
    },
  },

  { -- toggle.nvim
    "gregorias/toggle.nvim",
    -- version = "2.0",
    config = true,
  },

  {
    "johmsalas/text-case.nvim",
    lazy = false,
    opts = {
      substitude_command_name = "S",
    },
  },

  { -- REPL
    "Olical/conjure",
    branch = "main",
    dependencies = {
      -- https://github.com/guns/vim-sexp
      "guns/vim-sexp",
      -- https://github.com/tpope/vim-sexp-mappings-for-regular-people
      "tpope/vim-sexp-mappings-for-regular-people",
      --[[ {
        "PaterJason/cmp-conjure",
        config = function()
          local cmp = require("cmp")
          local config = cmp.get_config()
          table.insert(config.sources, {
            name = "buffer",
            option = {
              sources = {
                { name = "conjure" },
              },
            },
          })
          cmp.setup(config)
        end,
      }, ]]
    },
    config = function(_)
      require("conjure.main").main()
      require("conjure.mapping")["on-filetype"]()
    end,
    init = function()
      vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
        pattern = { "conjure-log-*" },
        callback = function(ev) vim.diagnostic.enable(false, { bufnr = ev.buf }) end,
      })
      vim.g["conjure#extract#tree_sitter#enabled"] = true
      vim.g["conjure#client#clojure#nrepl#refresh#backend"] = "clj-reload"
      -- Rebind from K
      vim.g["conjure#mapping#doc_word"] = "gk"
      -- Fix Babashka pprint: https://github.com/Olical/conjure/issues/406
      vim.g["conjure#client#clojure#nrepl#eval#print_function"] = "cider.nrepl.pprint/pprint"
      -- Disable REPL auto-start
      vim.g["conjure#client_on_load"] = false
      vim.g["conjure#log#hud#ignore_low_priority"] = true
    end,
  },

  {
    "kawre/leetcode.nvim",
    dependencies = {
      "nvim-telescope/telescope.nvim",
      "nvim-lua/plenary.nvim",
      "MunifTanjim/nui.nvim",
    },
    lazy = leet_arg ~= vim.fn.argv(0, -1),
    opts = {
      arg = leet_arg,
      injector = {
        ["cpp"] = { before = true },
        ["java"] = { before = true },
        ["python3"] = { before = true },
      },
      lang = "java",
    },
  },

  {
    "stevearc/resession.nvim",
    config = function()
      local resession = require("resession")
      resession.setup({})
      local function get_session_name()
        local name = vim.fn.getcwd()
        local branch = vim.trim(vim.fn.system("git branch --show-current"))
        if vim.v.shell_error == 0 then
          return name .. branch
        else
          return name
        end
      end
      vim.api.nvim_create_autocmd("StdinReadPre", {
        callback = function() vim.g.using_stdin = true end,
      })
      vim.api.nvim_create_autocmd("VimEnter", {
        callback = function()
          -- Only load the session if nvim was started with no args and without reading from stdin
          if vim.fn.argc(-1) == 0 and not vim.g.using_stdin then
            resession.load(get_session_name(), { dir = "dirsession", silence_errors = true })
          end
        end,
      })
      vim.api.nvim_create_autocmd("VimLeavePre", {
        callback = function()
          if resession.get_current() ~= nil then
            resession.save(get_session_name(), { dir = "dirsession", notify = false })
          end
        end,
      })
      vim.api.nvim_create_user_command(
        "Mksession",
        function() resession.save(get_session_name(), { dir = "dirsession" }) end,
        {}
      )
      vim.api.nvim_create_user_command(
        "Delsession",
        function() resession.delete(get_session_name(), { dir = "dirsession" }) end,
        {}
      )
    end,
  },

  {
    "MagicDuck/grug-far.nvim",
    opts = {},
  },

  { "godlygeek/tabular" },

  { "glacambre/firenvim", build = ":call firenvim#install(0)" },

  { import = "user.plugins" },
}, {
  dev = {
    path = "~/dev/github",
  },
  performance = {
    rtp = { paths = vim.g.nix.rtp },
  },
})

-- [[ Setting options ]]
-- See `:help vim.o`
-- NOTE: You can change these options as you wish!

-- Make line numbers default
vim.wo.number = true

-- Enable mouse mode
vim.o.mouse = "a"

-- Enable break indent
vim.o.breakindent = true

-- Save undo history
vim.o.undofile = true

-- Case-insensitive searching UNLESS \C or capital in search
vim.o.ignorecase = true
vim.o.smartcase = true

-- Keep signcolumn on by default
vim.wo.signcolumn = "yes"

-- Decrease update time
vim.o.updatetime = 250
vim.o.timeoutlen = 300

-- Set completeopt to have a better completion experience
vim.o.completeopt = "menuone,noselect"

-- NOTE: You should make sure your terminal supports this
vim.o.termguicolors = true

vim.o.foldcolumn = "0"
vim.o.foldlevel = 99 -- ufo needs a large value
vim.o.foldlevelstart = 99
vim.o.foldenable = true

-- [[ Basic Keymaps ]]

-- Keymaps for better default experience
-- See `:help vim.keymap.set()`
vim.keymap.set({ "n", "v" }, "<Space>", "<Nop>", { silent = true })

-- Remap for dealing with word wrap
vim.keymap.set("n", "k", "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })
vim.keymap.set("n", "j", "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })

-- Remap record macro to prevent accidental presses
vim.keymap.set("n", "<leader>q", "q", { noremap = true })
vim.keymap.set("n", "q", "<nop>", { noremap = true })

-- Diff view
vim.keymap.set("n", "<leader>hp", "<cmd>diffput<cr>", { noremap = true })
vim.keymap.set("n", "<leader>hg", "<cmd>diffget<cr>", { noremap = true })
vim.keymap.set("n", "<leader>hG", "<cmd>:1,$+1diffget<cr>", { noremap = true })
vim.keymap.set("n", "q", "<nop>", { noremap = true })

-- Search highlight
vim.keymap.set("n", "<Esc>", "<cmd>nohls<cr>", { silent = true, noremap = true })

-- Diagnostic keymaps

-- https://github.com/neovim/neovim/discussions/25588#discussioncomment-8700283
local function pos_equal(p1, p2)
  local r1, c1 = unpack(p1)
  local r2, c2 = unpack(p2)
  return r1 == r2 and c1 == c2
end

local function goto_error_diagnostic(f)
  return function()
    local pos_before = vim.api.nvim_win_get_cursor(0)
    f({ severity = vim.diagnostic.severity.ERROR, wrap = true })
    local pos_after = vim.api.nvim_win_get_cursor(0)
    if pos_equal(pos_before, pos_after) then f({ wrap = true }) end
  end
end

local ts_repeat_move = require("nvim-treesitter.textobjects.repeatable_move")
local next_diag_error, prev_diag_error = ts_repeat_move.make_repeatable_move_pair(
  goto_error_diagnostic(vim.diagnostic.goto_next),
  goto_error_diagnostic(vim.diagnostic.goto_prev)
)
vim.keymap.set("n", "]e", next_diag_error, { desc = "Go to next diagnostic" })
vim.keymap.set("n", "[e", prev_diag_error, { desc = "Go to previous error diagnostic" })
local next_diag, prev_diag =
  ts_repeat_move.make_repeatable_move_pair(vim.diagnostic.goto_next, vim.diagnostic.goto_prev)
vim.keymap.set("n", "]d", next_diag, { desc = "Go to next diagnostic" })
vim.keymap.set("n", "[d", prev_diag, { desc = "Go to previous diagnostic" })
vim.keymap.set("n", "<leader>e", vim.diagnostic.open_float, { desc = "Open floating diagnostic message" })
vim.keymap.set("n", "<leader>d", vim.diagnostic.setloclist, { desc = "Open diagnostics list" })

vim.keymap.set("n", "<leader>sv", function()
  -- source: https://github.com/creativenull
  for name, _ in pairs(package.loaded) do
    if name:match("^user") then package.loaded[name] = nil end
  end
  dofile(vim.env.MYVIMRC)
  vim.notify("Config reloaded", vim.log.levels.INFO)
end, { desc = "[S]ource [V]imrc" })

-- Quickfix keymaps
local next_quickfix, prev_quickfix = ts_repeat_move.make_repeatable_move_pair(vim.cmd.cnext, vim.cmd.cprev)
vim.keymap.set("n", "]q", next_quickfix, { desc = "Go to next quickfix item" })
vim.keymap.set("n", "[q", prev_quickfix, { desc = "Go to previous quickfix item" })
local last_quickfix, first_quickfix = ts_repeat_move.make_repeatable_move_pair(vim.cmd.clast, vim.cmd.cfirst)
vim.keymap.set("n", "]Q", last_quickfix, { desc = "Go to last quickfix item" })
vim.keymap.set("n", "[Q", first_quickfix, { desc = "Go to first quickfix item" })

if vim.fn.has("mac") == 1 then
  vim.g.open_cmd = "open"
elseif vim.fn.has("unix") == 1 then
  vim.g.open_cmd = "xdg-open"
end

-- Indentation
vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
  pattern = {
    "*.css",
    "*.gql",
    "*.graphql",
    "*.html",
    "*.js",
    "*.json",
    "*.jsx",
    "*.less",
    "*.sass",
    "*.scss",
    "*.ts",
    "*.tsx",
    "*.yaml",
    "*.yml",
  },
  callback = function()
    vim.bo.tabstop = 2
    vim.bo.softtabstop = 2
    vim.bo.shiftwidth = 2
  end,
})

-- https://neovim.discourse.group/t/how-to-add-custom-filetype-detection-to-various-env-files/4272/3
vim.filetype.add({
  -- Detect and assign filetype based on the extension of the filename
  extension = {
    mdx = "mdx",
    log = "log",
    conf = "conf",
    env = "sh",
  },
  -- Detect and apply filetypes based on the entire filename
  filename = {
    [".env"] = "sh",
    ["env"] = "sh",
    ["tsconfig.json"] = "jsonc",
  },
  -- Detect and apply filetypes based on certain patterns of the filenames
  pattern = {
    -- INFO: Match filenames like - ".env.example", ".env.local" and so on
    ["%.env%.[%w_.-]+"] = "sh",
  },
})

-- for GBrowse, now that netrw is disabled
vim.api.nvim_create_user_command(
  "Browse",
  function(opts) vim.fn.jobstart(vim.g.open_cmd .. " " .. vim.fn.shellescape(opts.fargs[1]), { detach = true }) end,
  { nargs = 1 }
)

-- [[ Highlight on yank ]]
-- See `:help vim.highlight.on_yank()`
local highlight_group = vim.api.nvim_create_augroup("YankHighlight", { clear = true })
vim.api.nvim_create_autocmd("TextYankPost", {
  callback = function() vim.highlight.on_yank() end,
  group = highlight_group,
  pattern = "*",
})

-- The line beneath this is called `modeline`. See `:help modeline`
-- vim: ts=2 sts=2 sw=2 et
