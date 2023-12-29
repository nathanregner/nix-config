vim.api.nvim_create_user_command("FormatDisable", function(args)
  if args.bang then
    -- FormatDisable! will disable formatting just for this buffer
    vim.b.disable_autoformat = true
  else
    vim.g.disable_autoformat = true
  end
end, {
  desc = "Disable autoformat-on-save",
  bang = true,
})
vim.api.nvim_create_user_command("FormatEnable", function()
  vim.b.disable_autoformat = false
  vim.g.disable_autoformat = false
end, {
  desc = "Re-enable autoformat-on-save",
})

-- Formatting
-- https://github.com/stevearc/conform.nvim
return {
  "stevearc/conform.nvim",
  opts = {
    formatters_by_ft = {
      css = { "prettierd" },
      gitcommit = { "prettier", "injected" }, -- FIXME: prettierd erroring out
      go = { "gofmt" },
      html = { "prettierd" },
      javascript = { "prettierd" },
      json = { "prettierd" },
      lua = { "stylua" },
      markdown = { "prettierd", "injected" },
      nix = { "nixfmt" },
      rust = { "rustfmt" },
      terraform = { "terraform_fmt" },
      yaml = { "prettierd" },

      -- all filetypes
      ["*"] = { "codespell", "trim_whitespace" },

      -- unspecified filetypes
      ["_"] = { "trim_whitespace" },
    },
    formatters = {
      prettier = { options = { ft_parsers = { gitcommit = "markdown" } } },
    },
    format_on_save = function(bufnr)
      -- Disable with a global or buffer-local variable
      if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
        return
      end
      return { timeout_ms = 500, lsp_fallback = true }
    end,
  },
}
