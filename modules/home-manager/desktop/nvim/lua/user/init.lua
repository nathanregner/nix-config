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
  command = "if mode() != 'c' | checktime | endif",
  pattern = { "*" },
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
local function nix_spec(spec)
  local name = vim.fs.basename(spec[1])
  if name == nil then return spec end

  local nix = vim.g.nix[string.lower(name)]
  if nix == nil then return spec end

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
    dev = true,
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

  {
    "NeogitOrg/neogit",
    dependencies = {
      "nvim-lua/plenary.nvim", -- required
      "sindrets/diffview.nvim", -- optional - Diff integration
      "nvim-telescope/telescope.nvim",
    },
    keys = { { "<leader>n", "<CMD>Neogit<CR>", desc = "Neogit" } },
    lazy = true,
    config = true,
  },

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

  { -- Autocompletion
    "hrsh7th/nvim-cmp",
    event = { "InsertEnter", "CmdlineEnter" },
    dependencies = {
      -- Snippet Engine & its associated nvim-cmp source
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
      "saadparwaiz1/cmp_luasnip",
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-path",
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-cmdline",
      "onsails/lspkind.nvim",
    },
    config = function() require("user.cmp") end,
  },

  { -- LSP Configuration & Plugins
    "neovim/nvim-lspconfig",
    dependencies = {
      "artemave/workspace-diagnostics.nvim",
      "dmmulroy/ts-error-translator.nvim",
      "folke/neoconf.nvim",
      "yioneko/nvim-vtsls",
    },
    config = function()
      local on_attach = function(client, bufnr)
        local map = function(mode, keys, func, desc)
          if desc then desc = "LSP: " .. desc end

          vim.keymap.set(mode, keys, func, { buffer = bufnr, desc = desc })
        end

        local nmap = function(keys, func, desc) map("n", keys, func, desc) end

        nmap("<leader>rn", vim.lsp.buf.rename, "[R]e[n]ame")
        map({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, "[C]ode [A]ction")
        nmap("<leader>fci", vim.lsp.buf.incoming_calls, "[F]ind [C]allers [I]ncoming")
        nmap("<leader>fca", vim.lsp.buf.outgoing_calls, "[F]ind [C]allers [O]outgoing")

        -- nmap("gd", require("telescope.builtin").lsp_definitions, "[G]oto [D]efinition")
        -- nmap("gr", require("telescope.builtin").lsp_references, "[G]oto [R]eferences")
        -- nmap("gI", require("telescope.builtin").lsp_implementations, "[G]oto [I]mplementation")
        -- nmap("<leader>D", require("telescope.builtin").lsp_type_definitions, "Type [D]efinition")
        -- nmap("<leader>ds", require("telescope.builtin").lsp_document_symbols, "[D]ocument [S]ymbols")
        -- nmap("<leader>ws", require("telescope.builtin").lsp_dynamic_workspace_symbols, "[W]orkspace [S]ymbols")

        -- See `:help K` for why this keymap
        nmap("K", vim.lsp.buf.hover, "Hover Documentation")
        nmap("<M-k>", vim.lsp.buf.signature_help, "Signature Documentation")

        -- Lesser used LSP functionality
        nmap("gD", vim.lsp.buf.declaration, "[G]oto [D]eclaration")
        nmap("<leader>wa", vim.lsp.buf.add_workspace_folder, "[W]orkspace [A]dd Folder")
        nmap("<leader>wr", vim.lsp.buf.remove_workspace_folder, "[W]orkspace [R]emove Folder")
        nmap(
          "<leader>wl",
          function() print(vim.inspect(vim.lsp.buf.list_workspace_folders())) end,
          "[W]orkspace [L]ist Folders"
        )

        -- Create a command `:Format` local to the LSP buffer
        vim.api.nvim_buf_create_user_command(
          bufnr,
          "Format",
          function(_) vim.lsp.buf.format() end,
          { desc = "Format current buffer with LSP" }
        )

        -- FIXME: breaks external file reload?
        -- if client.name == "vtsls" or client.name == "graphql" or client.name == "eslint" then
        --   require("workspace-diagnostics").populate_workspace_diagnostics(client, bufnr)
        -- end
      end

      -- https://github.com/neovim/neovim/issues/30985#issuecomment-2447329525
      for _, method in ipairs({ "textDocument/diagnostic", "workspace/diagnostic" }) do
        local default_diagnostic_handler = vim.lsp.handlers[method]
        vim.lsp.handlers[method] = function(err, result, context, config)
          if err ~= nil and err.code == -32802 then return end
          return default_diagnostic_handler(err, result, context, config)
        end
      end

      local downgrade_js_errors = function(method)
        local default_diagnostic_handler = vim.lsp.handlers[method]
        return function(err, result, context, config)
          require("ts-error-translator").translate_diagnostics(err, result, context)
          -- local log = require("vim.lsp.log")
          if result.uri:match(".*.js$") then
            -- log.error(result.diagnostics)
            for _, value in ipairs(result.diagnostics) do
              if value.severity == 1 then value.severity = 3 end
            end
          end

          return default_diagnostic_handler(err, result, context, config)
        end
      end

      local util = require("lspconfig.util")

      --- @class (partial) LspConfig : vim.lsp.ClientConfig
      --- @type { [string]: LspConfig }
      local servers = {
        ast_grep = {},
        bashls = {},
        clangd = {
          cmd = { -- https://www.reddit.com/r/neovim/comments/12qbcua/multiple_different_client_offset_encodings/
            "clangd",
            "--offset-encoding=utf-16",
          },
        },
        clojure_lsp = {
          root_dir = util.root_pattern("project.clj", "deps.edn", "bb.edn", ".git"),
        },
        -- https://github.com/olrtg/emmet-language-server
        -- https://code.visualstudio.com/docs/editor/emmet#_emmet-configuration
        emmet_language_server = {
          filetypes = {
            "css",
            "html",
            "javascript",
            "javascriptreact",
            "less",
            "pug",
            "sass",
            "scss",
            "typescriptreact",
            "xml",
          },
          init_options = {
            showSuggestionsAsSnippets = true,
            showExpandedAbbreviation = "always",
            includeLanguages = {
              javascript = "javascriptreact",
              -- typescript = "typescriptreact",
            },
          },
        },
        eslint = {},
        gopls = {},
        graphql = {
          filetypes = { "graphql", "javascript", "javascriptreact", "typescript", "typescriptreact" },
        },
        harper_ls = {
          settings = {
            -- https://writewithharper.com/docs/integrations/neovim
            -- https://github.com/Automattic/harper/blob/1dc6a185a985fcb2ca462b1b7cdd08cf9a199b3e/harper-core/src/linting/phrase_corrections.rs#L586
            ["harper-ls"] = {
              linters = {
                LongSentences = false,
                SentenceCapitalization = false,
                Spaces = false,
                ToDoHyphen = false,
              },
            },
          },
        },
        helm_ls = {
          settings = {
            ["helm-ls"] = {
              valuesFiles = {
                -- mainValuesFile = "values.yaml",
                -- lintOverlayValuesFile = "values.lint.yaml",
                additionalValuesFilesGlobPattern = "*values*.yaml",
              },
              yamlls = {
                enabled = true,
                diagnosticsLimit = 50,
                showDiagnosticsDirectly = false,
                path = "yaml-language-server",
                config = {
                  schemas = {
                    kubernetes = "templates/**",
                  },
                  completion = true,
                  hover = true,
                  -- any other config from https://github.com/redhat-developer/yaml-language-server#language-server-settings
                },
              },
            },
          },
        },
        html = { filetypes = { "html", "twig", "hbs" } },
        jsonls = {
          settings = {
            -- https://github.com/b0o/SchemaStore.nvim?tab=readme-ov-file
            json = {
              schemas = require("schemastore").json.schemas(),
              validate = { enable = true },
            },
          },
        },
        lua_ls = {
          Lua = {
            workspace = { checkThirdParty = false },
            telemetry = { enable = false },
            -- NOTE: toggle below to ignore Lua_LS's noisy `missing-fields` warnings
            -- diagnostics = { disable = { 'missing-fields' } },
          },
        },
        nil_ls = {},
        nixd = {},
        nushell = {},
        omnisharp = {
          cmd = { "OmniSharp" },
          settings = {
            RoslynExtensionsOptions = {
              EnableDecompilationSupport = true,
              EnableImportCompletion = true,
              AnalyzeOpenDocumentsOnly = false,
            },
          },
        },
        pyright = {},
        rust_analyzer = {
          -- https://rust-analyzer.github.io/manual.html#configuration
          settings = {
            ["rust-analyzer"] = {
              cargo = {
                allFeatures = true,
              },
              check = {
                command = "clippy",
              },
              completion = {
                autoimport = { enable = true },
              },
              files = {
                excludeDirs = { ".direnv", ".git" },
              },
            },
          },
        },
        terraformls = {
          root_dir = util.root_pattern(".terraform", ".terraform.lock.hcl", ".git"),
        },
        tflint = {
          root_dir = util.root_pattern(".terraform", ".terraform.lock.hcl", ".git", ".tflint.hcl"),
        },
        vtsls = vim.tbl_deep_extend("error", require("vtsls").lspconfig.default_config, {
          capabilities = {
            workspace = {
              didChangeWorkspaceFolders = {
                -- https://github.com/neovim/neovim/pull/22405
                -- https://github.com/neovim/neovim/issues/1380
                dynamicRegistration = true,
              },
            },
          },
          handlers = {
            ["textDocument/publishDiagnostics"] = function(err, result, ctx)
              require("ts-error-translator").translate_diagnostics(err, result, ctx)
              vim.lsp.diagnostic.on_publish_diagnostics(err, result, ctx)
            end,
            ["workspace/publishDiagnostics"] = function(err, result, ctx)
              require("ts-error-translator").translate_diagnostics(err, result, ctx)
              vim.lsp.diagnostic.on_publish_diagnostics(err, result, ctx)
            end,
          },
          settings = {
            -- https://github.com/microsoft/vscode/issues/13953
            typescript = { tsserver = { experimental = { enableProjectDiagnostics = true } } },
          },
        }),
        yamlls = {
          settings = {
            yaml = {
              -- https://github.com/b0o/SchemaStore.nvim?tab=readme-ov-file
              schemaStore = {
                -- You must disable built-in schemaStore support if you want to use
                -- this plugin and its advanced options like `ignore`.
                enable = false,
                -- Avoid TypeError: Cannot read properties of undefined (reading 'length')
                url = "",
              },
              schemas = require("schemastore").yaml.schemas(),
            },
          },
        },
      }

      local capabilities = vim.lsp.protocol.make_client_capabilities()
      capabilities = vim.tbl_deep_extend("force", capabilities, require("cmp_nvim_lsp").default_capabilities())

      for server_name, server_config in pairs(servers) do
        require("lspconfig")[server_name].setup({
          cmd = server_config.cmd,
          capabilities = capabilities,
          on_attach = on_attach,
          settings = server_config.settings,
          filetypes = server_config.filetypes,
          init_options = server_config.init_options,
          root_dir = server_config.root_dir,
        })
      end
    end,
  },

  {
    "folke/noice.nvim",
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
    "folke/lazydev.nvim",
    ft = "lua",
    dependencies = { "Bilal2453/luvit-meta", lazy = true }, -- optional `vim.uv` typings
    opts = {
      library = {
        { path = "luvit-meta/library", words = { "vim%.uv" } },
        -- { path = "lazy.nvim", words = { "LazySpec" } },
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

  { -- Theme
    -- https://github.com/catppuccin/nvim
    "catppuccin/nvim",
    version = "1.10.0", -- TODO: remove after https://github.com/catppuccin/nvim/discussions/903?
    name = "catppuccin",
    priority = 1000,
    opts = {
      flavour = "mocha",
      styles = {
        conditionals = {}, -- disable italics
      },
    },
    init = function() vim.cmd.colorscheme("catppuccin") end,
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
    lazy = false, -- https://github.com/stevearc/oil.nvim/issues/409
    keys = {
      { "-", function() require("oil").open() end },
    },
    opts = {
      keymaps = {
        ["gd"] = function()
          local oil = require("oil")
          if #require("oil.config").columns == 1 then
            oil.set_columns({ "icon", "permissions", "size", "mtime" })
          else
            oil.set_columns({ "icon" })
          end
        end,
        ["<Esc>"] = function()
          local oil = require("oil")
          local was_modified = vim.bo.modified
          if was_modified then
            local choice = vim.fn.confirm("Save changes?", "Yes\nNo", 1)
            if choice == 1 then oil.save() end
          end
          oil.close()
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
        ["g-"] = function()
          local oil = require("oil")
          local cwd = oil.get_current_dir()
          local git_root = get_git_root(cwd)
          if git_root == cwd then git_root = get_git_root(vim.fs.dirname(git_root)) end
          if git_root then oil.open(git_root) end
        end,
      },
    },
  },

  {
    "kylechui/nvim-surround",
    version = "*", -- Use for stability; omit to use `main` branch for the latest features
    event = "VeryLazy",
    config = function() require("user.surround") end,
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

  { -- TODO comments
    "folke/todo-comments.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    keys = function()
      local todo = require("todo-comments")
      local ts_repeat_move = require("nvim-treesitter.textobjects.repeatable_move")
      local jump_next, jump_prev = ts_repeat_move.make_repeatable_move_pair(todo.jump_next, todo.jump_prev)
      return {
        { "]t", jump_next, desc = "Next [T]odo comment" },
        { "[t", jump_prev, desc = "Previous [T]odo comment" },
      }
    end,
    opts = {
      signs = false,
      keywords = {
        TEST = nil,
      },
      highlight = {
        -- TODO
        -- TODO: asdf
        -- TODO asdf
        -- TODO (@someone): asdf
        pattern = {
          [[.*<(KEYWORDS)\s*:]],
          [[.*<(KEYWORDS)\s]],
          [[.*<(KEYWORDS)\(]],
          [[.*<(KEYWORDS)$]],
        },
      },
    },
  },

  { -- Neotest
    "nvim-neotest/neotest",
    dependencies = {
      "nvim-neotest/nvim-nio",
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",
      -- Adapters
      "marilari88/neotest-vitest",
      "nvim-neotest/neotest-jest",
      "rouge8/neotest-rust",
    },
    lazy = true,
    keys = {
      {
        "<localleader>tt",
        function(args)
          local neotest = require("neotest")
          neotest.run.run(args)
          neotest.summary.open()
        end,
        "[T]est [T]his",
      },

      {
        "<localleader>tf",
        function()
          local neotest = require("neotest")
          neotest.run.run(vim.fn.expand("%"))
          neotest.summary.open()
        end,
        "[T]est [F]ile",
      },
      {
        "<localleader>tq",
        function()
          local neotest = require("neotest")
          neotest.run.stop()
          neotest.watch.stop()
          neotest.summary.close()
        end,
        "[T]est [Q]uit",
      },
      {
        "<localleader>twt",
        function()
          local neotest = require("neotest")
          neotest.watch.watch()
          neotest.summary.open()
        end,
        "[T]est [W]atch [T]his",
      },
      { "<localleader>twq", function() neotest.watch.stop() end, "[T]est [W]atch [Q]uit" },
      { "<localleader>tr", function() neotest.output_panel.clear() end, "[T]est [R]eset logs" },
    },
    config = function()
      local neotest = require("neotest")
      ---@diagnostic disable-next-line: missing-fields
      neotest.setup({
        adapters = {
          require("neotest-rust")({
            args = { "--no-capture", "--cargo-quiet", "--cargo-quiet" },
          }),
          require("neotest-jest")({}),
          require("neotest-vitest"),
        },
        diagnostic = {
          enabled = true,
          severity = vim.diagnostic.severity.WARN,
        },
        ---@diagnostic disable-next-line: missing-fields
        output = {
          open_on_run = true,
          enter = true,
        },
      })
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
      local ts_repeat_move = require("nvim-treesitter.textobjects.repeatable_move")
      local trouble = require("trouble")
      local next, prev = ts_repeat_move.make_repeatable_move_pair(
        function() trouble.next({ jump = true }) end,
        function() trouble.prev({ jump = true }) end
      )
      vim.keymap.set("n", "]x", next, { desc = "Trouble next" })
      vim.keymap.set("n", "[x", prev, { desc = "Trouble prev" })
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

  { "Olical/nfnl" },

  {
    "julienvincent/nvim-paredit",
    opts = function()
      local paredit = require("nvim-paredit")
      return {
        keys = {
          -- FIXME (test)
          --       ^
          ["<localleader>i"] = {
            function()
              local range = paredit.api.wrap_enclosing_form_under_cursor("( ", ")")
              vim.print(range)
              if range then
                vim.api.nvim_win_set_cursor(0, { range[1] + 1, range[2] + 1 })
                vim.cmd("startinsert")
              end
            end,
            "Wrap form",
          },
          ["<localleader>I"] = {
            function()
              local range = paredit.api.wrap_element_under_cursor("( ", ")")
              vim.print(range)
              if range then
                vim.api.nvim_win_set_cursor(0, { range[1] + 1, range[2] + 1 })
                vim.cmd("startinsert")
              end
            end,
            "Wrap element",
          },
        },
      }
    end,
  },

  { -- REPL
    "Olical/conjure",
    branch = "main",
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
      -- vim.g["conjure#client_on_load"] = false
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
