require("user.snippets.all")
require("user.snippets.ecma")

for _, module in ipairs(vim.g.nix.luasnip.extraModules or {}) do
  require(module)
end
