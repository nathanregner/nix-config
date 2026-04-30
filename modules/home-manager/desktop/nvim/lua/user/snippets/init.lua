require("user.snippets.all")
require("user.snippets.ecma")
require("user.snippets.java")
require("user.snippets.nix")
require("user.snippets.rust")
require("user.snippets.typescriptreact")

for _, module in ipairs(vim.g.nix.luasnip.extraModules or {}) do
  require(module)
end
