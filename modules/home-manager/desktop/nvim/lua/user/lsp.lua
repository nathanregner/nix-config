local on_attach = function(_, bufnr)
  local map = function(mode, keys, func, desc)
    if desc then desc = "LSP: " .. desc end

    vim.keymap.set(mode, keys, func, { buffer = bufnr, desc = desc })
  end

  local nmap = function(keys, func, desc) map("n", keys, func, desc) end

  nmap("<leader>rn", function()
    local success, ts_autotag = pcall(require, "ts-autotag")
    if not success or not ts_autotag.rename() then vim.lsp.buf.rename() end
  end, "[R]e[n]ame")
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

--- @type { [string]: vim.lsp.Config }
local servers = {
  ast_grep = {},
  basedpyright = {},
  bashls = {},
  clangd = {
    cmd = { -- https://www.reddit.com/r/neovim/comments/12qbcua/multiple_different_client_offset_encodings/
      "clangd",
      "--offset-encoding=utf-16",
    },
  },
  clojure_lsp = {
    -- root_dir = util.root_pattern("project.clj", "deps.edn", "bb.edn", ".git"),
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
  terraformls = {
    -- root_dir = util.root_pattern(".terraform", ".terraform.lock.hcl", ".git"),
  },
  tflint = {
    -- root_dir = util.root_pattern(".terraform", ".terraform.lock.hcl", ".git", ".tflint.hcl"),
  },
  tinymist = {},
  tsgo = {
    cmd = { "tsgo", "--lsp", "--stdio" },
    filetypes = {
      "javascript",
      "javascript.jsx",
      "javascriptreact",
      "typescript",
      "typescript.tsx",
      "typescriptreact",
    },
    root_dir = require("lspconfig.util").root_pattern(
      ".git",
      "jsconfig.json",
      "package.json",
      "tsconfig.base.json",
      "tsconfig.json"
    ),
    settings = {},
    single_file_support = true,
  },
  vtsls = {
    capabilities = {
      workspace = {
        didChangeWorkspaceFolders = {
          -- https://github.com/neovim/neovim/pull/22405
          -- https://github.com/neovim/neovim/issues/1380
          dynamicRegistration = true,
        },
      },
    },
    -- handlers = {
    --   ["textDocument/publishDiagnostics"] = function(err, result, ctx)
    --     require("ts-error-translator").translate_diagnostics(err, result, ctx)
    --     vim.lsp.diagnostic.on_publish_diagnostics(err, result, ctx)
    --   end,
    --   ["workspace/publishDiagnostics"] = function(err, result, ctx)
    --     require("ts-error-translator").translate_diagnostics(err, result, ctx)
    --     vim.lsp.diagnostic.on_publish_diagnostics(err, result, ctx)
    --   end,
    -- },
    settings = {
      javascript = {
        updateImportsOnFileMove = "always",
      },
      typescript = {
        updateImportsOnFileMove = "always",
        -- https://github.com/microsoft/vscode/issues/13953
        tsserver = { experimental = { enableProjectDiagnostics = true } },
      },
      vtsls = {
        enableMoveToFileCodeAction = true,
      },
    },
  },
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
capabilities = vim.tbl_deep_extend("force", capabilities, require("blink.cmp").get_lsp_capabilities({}, false))

for server_name, server_config in pairs(servers) do
  if server_config.capabilities then
    capabilities = vim.tbl_deep_extend("force", capabilities, server_config.capabilities)
  end
  vim.lsp.config(server_name, {
    cmd = server_config.cmd,
    capabilities = capabilities,
    on_attach = function(...)
      on_attach(...)
      if server_config.on_attach then server_config.on_attach(...) end
    end,
    settings = server_config.settings,
    filetypes = server_config.filetypes,
    init_options = server_config.init_options,
    root_dir = server_config.root_dir,
  })
  vim.lsp.enable(server_name)
end
