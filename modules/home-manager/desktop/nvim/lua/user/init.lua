-- disable netrw
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

vim.opt.diffopt = "internal,filler,closeoff,indent-heuristic,linematch:60,algorithm:histogram"

local function find_git_root()
  -- Use the current buffer's path as the starting point for the git search
  local current_file = vim.api.nvim_buf_get_name(0)
  current_file = string.gsub(current_file, "^oil://", "")
  local current_dir
  local cwd = vim.fn.getcwd()
  -- If the buffer is not associated with a file, return nil
  if current_file == "" then
    current_dir = cwd
  else
    -- Extract the directory from the current file's path
    current_dir = vim.fn.fnamemodify(current_file, ":h")
  end

  -- Find the Git root directory from the current file's path
  local git_root = vim.fn.systemlist("git -C " .. vim.fn.escape(current_dir, " ") .. " rev-parse --show-toplevel")[1]
  if vim.v.shell_error ~= 0 then
    print("Not a git repository. Searching on current working directory")
    return cwd
  end
  return git_root
end

vim.g.fugitive_legacy_commands = 0

local leet_arg = "leetcode.nvim"

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
    "altermo/ultimate-autopair.nvim",
    event = { "InsertEnter", "CmdlineEnter" },
    branch = "v0.6",
    opts = function()
      return {
        cmap = false,
        close = {
          enable = true,
          map = "<C-S-Enter>",
          cmap = "<C-S-Enter>",
          conf = {},
        },
        extensions = {
          cond = {
            cond = function(fn) return not fn.in_node("comment") end,
          },
          filetype = { nft = { "TelescopePrompt", "snacks_picker_input" } },
        },
        internal_pairs = {
          {
            "''",
            "''",
            newline = true,
            ft = { "nix" },
            cond = function(fn)
              return not fn.in_node({
                "indented_string_expression",
                "string_fragment",
              })
            end,
          },
          unpack(require("ultimate-autopair.default").conf.internal_pairs),
        },
      }
    end,
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
        provider_selector = function() return { "treesitter", "indent" } end,
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
    keys = {
      { "<leader>n", function() vim.cmd("Bufferize Fidget history") end, desc = "Notification History" },
    },
  },

  { -- Notifications + LSP Progress Messages
    "j-hui/fidget.nvim",
    ---@type fidget.config
    opts = {
      notification = {
        override_vim_notify = true,
      },
    },
  },

  { "towolf/vim-helm", ft = "helm" },

  { -- LSP Configuration & Plugins
    "neovim/nvim-lspconfig",
    dependencies = {
      "artemave/workspace-diagnostics.nvim",
      "j-hui/fidget.nvim",
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

      local util = require("lspconfig.util")

      local servers = {
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
        emmet_language_server = {
          filetypes = {
            "css",
            "html",
            "javascript",
            "javascriptreact",
            "less",
            "sass",
            "scss",
            "pug",
            "typescriptreact",
          },
          init_options = {
            showSuggestionsAsSnippets = true,
            showExpandedAbbreviation = "inMarkupAndStylesheetFilesOnly",
            includeLanguages = {
              javascript = "javascriptreact",
              typescript = "typescriptreact",
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
            ["harper-ls"] = { -- https://writewithharper.com/docs/integrations/neovim
              linters = {
                long_sentences = false,
                sentence_capitalization = false,
                spaces = false,
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
        nil_ls = {},
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
          settings = {
            -- https://github.com/microsoft/vscode/issues/13953
            typescript = { tsserver = { experimental = { enableProjectDiagnostics = true } } },
          },
          capabilities = {
            workspace = {
              didChangeWorkspaceFolders = {
                -- https://github.com/neovim/neovim/pull/22405
                -- https://github.com/neovim/neovim/issues/1380
                dynamicRegistration = true,
              },
            },
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

        lua_ls = {
          Lua = {
            workspace = { checkThirdParty = false },
            telemetry = { enable = false },
            -- NOTE: toggle below to ignore Lua_LS's noisy `missing-fields` warnings
            -- diagnostics = { disable = { 'missing-fields' } },
          },
        },
      }

      for server_name, server_config in pairs(servers) do
        require("lspconfig")[server_name].setup({
          cmd = server_config.cmd,
          capabilities = require("blink.cmp").get_lsp_capabilities(server_config.capabilities),
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
    "folke/lazydev.nvim",
    ft = "lua",
    -- dependencies = { "Bilal2453/luvit-meta", lazy = true }, -- optional `vim.uv` typings
    opts = {
      library = {
        -- { path = "luvit-meta/library", words = { "vim%.uv" } },
        -- { path = "lazy.nvim", words = { "LazySpec" } },
      },
    },
  },

  "b0o/schemastore.nvim",

  { -- Autoformat
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        bash = { "shfmt" },
        clojure = { "joker" },
        css = { "prettierd" },
        fennel = { "fnlfmt" },
        gitcommit = { "prettier", "injected" }, -- FIXME: prettierd erroring out
        go = { "gofmt" },
        graphql = { "prettierd" },
        html = { "prettierd" },
        javascript = { "prettierd" },
        javascriptreact = { "prettierd" },
        json = { "prettierd" },
        jsonc = { "prettierd" },
        lua = { "stylua" },
        markdown = { "prettierd", "injected" },
        nginx = { "nginxfmt" },
        nix = {
          "nixfmt", --[[ "injected" ]]
        }, -- FIXME: injected bash formatter broken
        rust = { "rustfmt" },
        sh = { "shfmt" },
        terraform = { "terraform_fmt" },
        toml = { "taplo" },
        typescript = { "prettierd" },
        typescriptreact = { "prettierd" },
        vue = { "prettierd" },
        yaml = { "prettierd" },
        zsh = { "shfmt" },

        -- all filetypes
        ["*"] = { "trim_whitespace" },

        -- unspecified filetypes
        ["_"] = { "trim_whitespace" },
      },
      formatters = {
        prettier = { options = { ft_parsers = { gitcommit = "markdown" } } },
        nginxfmt = {
          command = "nginxfmt",
          args = { "--pipe" },
        },
      },
      format_on_save = function(bufnr)
        -- Disable with a global or buffer-local variable
        if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then return end
        return { timeout_ms = 500, lsp_format = "fallback" }
      end,
    },
    config = function(_, opts)
      require("conform").setup(opts)

      vim.api.nvim_create_user_command("FormatDisable", function(args)
        if args.bang then
          vim.g.disable_autoformat = true
        else
          ---@diagnostic disable-next-line: inject-field
          vim.b.disable_autoformat = true
        end
      end, {
        desc = "Disable autoformat-on-save",
        bang = true,
      })
      vim.api.nvim_create_user_command("FormatEnable", function(args)
        if args.bang then vim.g.disable_autoformat = false end
        ---@diagnostic disable-next-line: inject-field
        vim.b.disable_autoformat = false
      end, {
        desc = "Re-enable autoformat-on-save",
      })
    end,
  },

  {
    "folke/which-key.nvim",
    config = function()
      ---@diagnostic disable-next-line: missing-fields
      require("which-key").setup({})
      require("which-key").register({
        ["<leader>c"] = { name = "[C]ode", _ = "which_key_ignore" },
        ["<leader>d"] = { name = "[D]ocument", _ = "which_key_ignore" },
        ["<leader>g"] = { name = "[G]it", _ = "which_key_ignore" },
        ["<leader>h"] = { name = "More git", _ = "which_key_ignore" },
        ["<leader>r"] = { name = "[R]ename", _ = "which_key_ignore" },
        ["<leader>f"] = { name = "[F]ind", _ = "which_key_ignore" },
        ["<leader>w"] = { name = "[W]orkspace", _ = "which_key_ignore" },
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
    name = "catppuccin",
    priority = 1000,
    opts = {
      flavour = "mocha",
      styles = {
        conditionals = {}, -- disable italics
      },
      integrations = {
        snacks = true,
      },
      -- https://github.com/catppuccin/nvim/issues/823
      custom_highlights = function(colors)
        return {
          NormalFloat = { bg = colors.base, fg = colors.text },
        }
      end,
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
        lualine_y = { "progress" },
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
      default_mappings = true,
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
      {
        "-",
        function() require("oil").open() end,
      },
    },
    opts = {
      keymaps = {
        ["1"] = function() require("oil").open(find_git_root()) end,
        ["<Esc>"] = function()
          local oil = require("oil")
          local was_modified = vim.bo.modified
          if was_modified then
            local choice = vim.fn.confirm("Save changes?", "Yes\nNo", 1)
            if choice == 1 then oil.save() end
          end
          oil.close()
        end,
      },
    },
  },

  {
    "stevearc/oil.nvim",
    dependencies = { { "nvim-tree/nvim-web-devicons", opts = {} } },
    lazy = false,
    keys = {
      {
        "-",
        function() require("oil").open() end,
      },
    },
    opts = {
      keymaps = {
        ["1"] = function() require("oil").open(find_git_root()) end,
        ["<Esc>"] = function()
          local oil = require("oil")
          local was_modified = vim.bo.modified
          if was_modified then
            local choice = vim.fn.confirm("Save changes?", "Yes\nNo", 1)
            if choice == 1 then oil.save() end
          end
          oil.close()
        end,
      },
    },
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
        -- { "]T", jump_next, desc = "Next [T]odo comment" },
        -- { "[T", jump_prev, desc = "Previous [T]odo comment" },
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
      "antoinemadec/FixCursorHold.nvim",
      "nvim-treesitter/nvim-treesitter",
      -- Adapters
      "marilari88/neotest-vitest",
      "nvim-neotest/neotest-jest",
      "rouge8/neotest-rust",
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

      -- :run_all_tests "ta"
      -- :run_current_ns_tests "tn"
      -- :run_alternate_ns_tests "tN"
      -- :run_current_test "tc"
      local nmap = function(keys, func, desc) vim.keymap.set("n", keys, func, { desc = desc }) end

      local show_summary = function() neotest.summary.open() end

      nmap("<localleader>tt", function(args)
        neotest.run.run(args)
        show_summary()
      end, "[T]est [T]his")
      nmap("<localleader>tf", function()
        neotest.run.run(vim.fn.expand("%"))
        show_summary()
      end, "[T]est [F]ile")
      nmap("<localleader>tq", function()
        neotest.run.stop()
        neotest.watch.stop()
        neotest.summary.close()
      end, "[T]est [Q]uit")
      nmap("<localleader>twt", function()
        neotest.watch.watch()
        show_summary()
      end, "[T]est [W]atch [T]his")
      nmap("<localleader>twq", function() neotest.watch.stop() end, "[T]est [W]atch [Q]uit")
      nmap("<localleader>tr", function() neotest.output_panel.clear() end, "[T]est [R]eset logs")
    end,
  },

  { "nvim-lua/plenary.nvim", dev = true },

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
      local next, prev = ts_repeat_move.make_repeatable_move_pair(require("trouble").next, require("trouble").prev)
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

  { -- coerce.nvim
    "gregorias/coerce.nvim",
    -- version = "3.0",
    config = function()
      require("coerce").setup()
      require("coerce").register_case({
        keymap = "K",
        description = "Kebab-Case",
        case = function(str)
          local cc = require("coerce.case")
          local cs = require("coerce.string")
          local parts = cc.split - keyword(str)

          for i = 1, #parts, 1 do
            local part_graphemes = cs.str2graphemelist(parts[i])
            part_graphemes[1] = vim.fn.toupper(part_graphemes[1])
            parts[i] = table.concat(part_graphemes, "")
          end

          return table.concat(parts, "-")
        end,
      })
    end,
  },

  { "Olical/nfnl" },

  {
    "julienvincent/nvim-paredit",
    opts = function()
      local paredit = require("nvim-paredit")
      return {
        keys = {
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

  { import = "user.plugins" },
}, {
  dev = {
    path = "~/dev/github",
  },
  performance = {
    rtp = { paths = vim.g.nix.rtp },
  },
})

-- https://trstringer.com/neovim-auto-reopen-files/
vim.api.nvim_create_autocmd("VimLeavePre", {
  pattern = "*",
  callback = function()
    if vim.g.savesession then vim.api.nvim_command("mks!") end
  end,
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
vim.keymap.set("n", "<leader>hP", "<cmd>:1,$+1diffput<cr>", { noremap = true })
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
-- vim: ts=2 sts=3 sw=2 et
