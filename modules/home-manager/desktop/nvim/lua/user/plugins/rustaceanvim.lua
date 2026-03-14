-- https://github.com/mrcjkb/rustaceanvim?tab=readme-ov-file#books-usage--features
-- TODO: parentModule bind

---@type rustaceanvim.Opts
vim.g.rustaceanvim = {
  settings = {
    -- https://rust-analyzer.github.io/manual.html#configuration
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
}

---@module "lazy"
---@type LazySpec
return {
  "mrcjkb/rustaceanvim",
  version = "^6",
  lazy = false, -- This plugin is already lazy
}
