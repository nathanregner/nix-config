vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    if client then client.server_capabilities.semanticTokensProvider = nil end
  end,
})

---@module "lazy"
---@type LazySpec
return {
  "neovim/nvim-lspconfig",
  dependencies = {
    "artemave/workspace-diagnostics.nvim",
    "folke/neoconf.nvim",
    "yioneko/nvim-vtsls",
  },
  config = function() require("user.lsp") end,
}
