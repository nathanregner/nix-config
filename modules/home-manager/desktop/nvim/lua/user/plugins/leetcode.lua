local leet_arg = "leetcode.nvim"

---@module "lazy"
---@type LazySpec
return {
  "kawre/leetcode.nvim",
  dependencies = {
    "nvim-telescope/telescope.nvim",
    "nvim-lua/plenary.nvim",
    "MunifTanjim/nui.nvim",
  },
  lazy = leet_arg ~= vim.fn.argv(0, -1),
  opts = {
    arg = leet_arg,
    injector = {
      ["cpp"] = { before = true },
      ["java"] = { before = true },
      ["python3"] = { before = true },
    },
    lang = "java",
  },
}
