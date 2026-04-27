local M = {}

local function shadafile(project_dir)
  local hash = vim.fn.sha256(project_dir):sub(1, 40)
  local name = project_dir:gsub("[^a-zA-Z0-9]", "-")
  return hash .. name
end

M.update = function()
  local git = require("user.git")
  git.root()

  local ok, root = pcall(git.root)
  if not ok then return end

  vim.opt.shadafile = vim.fn.stdpath("state") .. "/shada/" .. shadafile(root)
end

M.setup = function()
  M.update()

  -- local group = vim.api.nvim_create_augroup("user.shada", { clear = true })
  -- vim.api.nvim_create_autocmd("DirChanged", {
  --   group = group,
  --   callback = function()
  --     M.update()
  --     -- Add your custom logic here (e.g., refresh a plugin)
  --   end,
  -- })
end

return M
