require("conform").setup({
  formatters_by_ft = {
    bash = { "shfmt" },
    clojure = { "joker" },
    css = { "prettierd" },
    fennel = { "fnlfmt" },
    gitcommit = { "prettier", "injected" }, -- FIXME: prettierd erroring out
    go = { "gofmt" },
    graphql = { "prettierd" },
    html = { "prettierd" },
    java = { "spring_javaformat" },
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
    nginxfmt = {
      command = "nginxfmt",
      args = { "--pipe" },
    },
    prettier = { options = { ft_parsers = { gitcommit = "markdown" } } },
    spring_javaformat = {
      command = "spring-javaformat",
      args = { "$FILENAME" },
      stdin = true,
    },
  },
  format_on_save = function(bufnr)
    local settings = require("user.neoconf.conform").settings()

    -- global disabled?
    if not settings.enabled then return end

    -- filetype disabled?
    local ft = vim.bo[bufnr].filetype
    if settings.filetypes[ft] == false then return end

    -- buffer disabled?
    if vim.b[bufnr].format_on_save == false then return end

    return { timeout_ms = 500, lsp_format = "fallback" }
  end,
})

-- TODO: writeback to config

vim.api.nvim_create_user_command("FormatDisable", function(args)
  ---@diagnostic disable-next-line: inject-field
  vim.b.format_on_save = false
end, {
  desc = "Disable autoformat-on-save",
  bang = true,
})

vim.api.nvim_create_user_command("FormatEnable", function(args)
  ---@diagnostic disable-next-line: inject-field
  vim.b.format_on_save = true
end, {
  desc = "Re-enable autoformat-on-save",
})
