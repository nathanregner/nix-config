require("user.snippets.all")
require("user.snippets.ecma")
require("user.snippets.rust")

for _, module in ipairs(vim.g.nix.luasnip.extraModules or {}) do
  require(module)
end
