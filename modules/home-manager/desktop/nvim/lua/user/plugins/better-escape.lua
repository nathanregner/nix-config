---@module "lazy"
---@type LazySpec
return {
  "max397574/better-escape.nvim",
  opts = {
    default_mappings = false,
    mappings = {
      i = { j = { k = "<Esc>" } },
      c = { j = { k = "<Esc>" } },
      t = { j = { k = "<C-\\><C-n>" } },
      v = { j = { k = "<Esc>" } },
      s = { j = { k = "<Esc>" } },
    },
  },
}
