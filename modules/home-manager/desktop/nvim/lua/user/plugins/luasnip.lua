---@module "lazy"
---@type LazySpec
return nix_spec({
  "L3MON4D3/LuaSnip",
  dependencies = {
    "rafamadriz/friendly-snippets",
    {
      "chrisgrieser/nvim-scissors",
      opts = {
        snippetDir = vim.fn.stdpath("config") .. "/snippets",
      },
    },
  },
  config = function()
    require("luasnip").config.setup({
      enable_autosnippets = true,
      store_selection_keys = "<Tab>",
    })
    require("luasnip.loaders.from_vscode").lazy_load()
    require("luasnip.loaders.from_vscode").lazy_load({
      paths = { vim.fn.stdpath("config") .. "/snippets" },
    })
    require("user.snippets")
  end,
})
