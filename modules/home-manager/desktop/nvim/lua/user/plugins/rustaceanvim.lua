-- https://github.com/mrcjkb/rustaceanvim?tab=readme-ov-file#books-usage--features
-- TODO: parentModule bind

---@type rustaceanvim.Opts
vim.g.rustaceanvim = {
  server = {
    default_settings = {
      -- https://rust-analyzer.github.io/manual.html#configuration
      ["rust-analyzer"] = {
        cargo = {
          allFeatures = true,
          -- https://github.com/rust-lang/rust-analyzer/issues/10684
          -- fixes build scripts constantly re-running
          targetDir = "target/rust-analyzer",
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
}

---@module "lazy"
---@type LazySpec
return {
  "mrcjkb/rustaceanvim",
  lazy = false, -- This plugin is already lazy
}
