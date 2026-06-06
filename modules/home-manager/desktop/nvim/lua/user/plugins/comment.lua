---@module "lazy"
---@type LazySpec
return {
  "nathanregner/Comment.nvim",
  dependencies = {
    { "JoosepAlviste/nvim-ts-context-commentstring", opts = { enable_autocmd = false } },
  },
  config = function()
    local ft = require("Comment.ft")
    ft.ld = { "/* %s */", "/* %s */" }

    ---@diagnostic disable-next-line: missing-fields
    require("Comment").setup({
      pre_hook = require("ts_context_commentstring.integrations.comment_nvim").create_pre_hook(),
    })
  end,
}
