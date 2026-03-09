local M = {}

local function get_buffer_cwd()
  -- Use the current buffer's path as the starting point for the git search
  local current_file = vim.api.nvim_buf_get_name(0)
  current_file = string.gsub(current_file, "^oil://", "")
  local cwd = vim.fn.getcwd()
  -- If the buffer is not associated with a file, return nil
  if current_file == "" then
    cwd = cwd
  else
    -- Extract the directory from the current file's path
    cwd = vim.fn.fnamemodify(current_file, ":h")
  end
  return cwd
end

---@param args string
---@param cwd? string
---@return string
local function git(args, cwd)
  cwd = cwd or get_buffer_cwd()
  return vim.fn.systemlist("git -C " .. vim.fn.escape(cwd, " ") .. " " .. args)[1]
end

---@param cwd? string
M.root = function(cwd) return git("rev-parse --show-toplevel", cwd) end

---@param cwd? string
M.default_branch = function(cwd) return git("default-branch", cwd) end

---@param cwd? string
M.merge_base = function(branch, cwd) return git("merge-base HEAD " .. branch, cwd) end

return M
