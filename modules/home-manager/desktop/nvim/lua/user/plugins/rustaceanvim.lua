-- https://github.com/mrcjkb/rustaceanvim?tab=readme-ov-file#books-usage--features
-- TODO: parentModule bind

---@type rustaceanvim.Opts
vim.g.rustaceanvim = {
  dap = {},
  server = {
    default_settings = {
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
  },
  tools = {
    -- enable_nextest = true, -- FIXME: buggy out of order test output on reset
    enable_nextest = false,
  },
}

---@module "lazy"
---@type LazySpec
return {
  "mrcjkb/rustaceanvim",
  version = "^6",
  lazy = false, -- This plugin is already lazy
}
