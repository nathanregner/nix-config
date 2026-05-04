---@module "lazy"
---@type LazySpec
return {
  "mbbill/undotree",
  keys = {
    { "<leader>fu", vim.cmd.UndotreeToggle, desc = "[F]ile [U]ndo Tree" },
  },
  config = function() vim.g.undotree_WindowLayout = 4 end,
}
