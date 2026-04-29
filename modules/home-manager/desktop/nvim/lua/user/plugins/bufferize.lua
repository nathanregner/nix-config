---@module "lazy"
---@type LazySpec
return {
  "AndrewRadev/bufferize.vim",
  event = "CmdlineEnter",
  config = function() vim.api.nvim_create_user_command("Msgs", "Bufferize messages", { desc = "Bufferize messages" }) end,
}
