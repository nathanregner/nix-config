local slow = {
  nu = true,
}

local enabled = function(bufnr, before)
  local settings = require("user.neoconf.conform").settings()

  -- global disabled?
  if not settings.enabled then return false end

  if vim.g.format_on_save == false then return false end

  -- filetype disabled?
  local ft = vim.bo[bufnr].filetype
  if settings.filetypes[ft] == false then return false end

  -- buffer disabled?
  if vim.b[bufnr].format_on_save == false then return false end

  if before and slow[ft] then return false end

  return true
end

local log = require("user.log").create("conform")

require("conform").setup({
  formatters_by_ft = {
    bash = { "shfmt" },
    c = { "clang-format" },
    clojure = { "joker" },
    cpp = { "clang-format" },
    css = { "prettierd" },
    fennel = { "fnlfmt" },
    gitcommit = { "injected" },
    go = { "gofmt" },
    graphql = { "prettierd" },
    html = { "prettierd" },
    java = { "spring_javaformat" },
    javascript = { "prettierd", "lsp_organize_imports" },
    javascriptreact = { "prettierd", "lsp_organize_imports" },
    json = { "prettierd" },
    jsonc = { "prettierd" },
    lua = { "stylua" },
    markdown = { "prettierd", "injected" },
    nginx = { "nginxfmt" },
    nix = {
      "nixfmt",
      -- "injected",
    },
    nu = { "topiary_nu" },
    python = {
      "ruff_fix",
      "ruff_format",
      "ruff_organize_imports",
    },
    query = { "topiary_tree_sitter_query" },
    rust = { "rustfmt", "injected" },
    sh = { "shfmt" },
    terraform = { "terraform_fmt", "injected" },
    toml = { "taplo" },
    typescript = { "prettierd", "lsp_organize_imports" },
    typescriptreact = { "prettierd", "lsp_organize_imports" },
    typst = { "typstyle" },
    vue = { "prettierd" },
    yaml = { "prettierd" },
    zsh = { "shfmt" },

    -- all filetypes
    ["*"] = { "trim_whitespace" },

    -- unspecified filetypes
    ["_"] = { "trim_whitespace" },
  },
  formatters = {
    lsp_organize_imports = {
      format = function(self, ctx, lines, callback)
        -- vim.lsp.buf.code_action({
        --   context = { only = { "source.organizeImports" } },
        --   apply = true,
        -- })
        -- 1. Fetch code actions synchronously from the LSP (blocks until done or timeout)
        -- local responses =
        --   vim.lsp.buf_request_sync(ctx.buf, "textDocument/codeAction", { only = { "source.organizeImports" } }, 1000)
        --
        -- if not responses or vim.tbl_isempty(responses) then
        --   return callback(nil) -- No actions found, skip to next formatter safely
        -- end
        --
        -- -- 2. Iterate through responses to find and apply the edit immediately
        -- for _, response in pairs(responses) do
        --   log("response: " .. vim.print(response))
        --   if response.result then
        --     for _, action in ipairs(response.result) do
        --       -- Handle workspace edits if provided directly by the action
        --       if action.edit then
        --         vim.lsp.util.apply_workspace_edit(action.edit, "utf-8")
        --       -- Handle command resolving if the action requires execution
        --       elseif action.command then
        --         vim.lsp.buf.execute_command(action.command)
        --       end
        --     end
        --   end
        -- end
        --
        -- -- 3. The edits are guaranteed to be in the buffer now; proceed safely
        callback(nil)
      end,
    },
    nginxfmt = {
      command = "nginxfmt",
      args = { "--pipe" },
    },
    prettier = { options = { ft_parsers = { gitcommit = "markdown" } } },
    spring_javaformat = {
      command = "spring-javaformat",
      args = { "$FILENAME" },
      stdin = true,
      condition = function(_, ctx)
        return vim.fs.find(".springjavaformatconfig", { path = ctx.dirname, upward = true })[1] ~= nil
      end,
    },
    taplo = {
      command = "taplo",
      args = { "fmt", "-" },
      cwd = function(_, ctx) return ctx.dirname end,
      stdin = true,
    },
    topiary_nu = {
      command = "topiary",
      args = { "format", "--language", "nu" },
    },
    topiary_tree_sitter_query = {
      command = "topiary",
      args = { "format", "--language", "tree_sitter_query" },
    },
  },
  format_on_save = function(bufnr)
    if not enabled(bufnr, true) then return end
    return { timeout_ms = 500, lsp_format = "fallback" }
  end,
  format_after_save = function(bufnr)
    if not enabled(bufnr, false) then return end
    return { async = true, lsp_format = "fallback" }
  end,
})

-- TODO: writeback to config

vim.api.nvim_create_user_command("FormatDisable", function(args)
  if args.bang then
    vim.g.format_on_save = false
  else
    vim.b.format_on_save = false
  end
end, {
  desc = "Disable autoformat-on-save",
  bang = true,
})

vim.api.nvim_create_user_command("FormatEnable", function(args)
  if args.bang then
    vim.g.format_on_save = true
  else
    vim.b.format_on_save = true
  end
end, {
  desc = "Re-enable autoformat-on-save",
})
