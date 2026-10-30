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
---@return string?
local function git(args, cwd)
  cwd = cwd or get_buffer_cwd()
  local result = vim.fn.systemlist("git -C " .. vim.fn.escape(cwd, " ") .. " " .. args .. " 2>/dev/null")[1]
  if vim.v.shell_error ~= 0 then return nil end
  return result
end

---@param cwd? string
M.root = function(cwd) return git("rev-parse --show-toplevel", cwd) end

---@param cwd? string
M.default_branch = function(cwd) return git("default-branch", cwd) end

---@param cwd? string
M.merge_base = function(branch, cwd) return git("merge-base HEAD " .. branch, cwd) end

---@param cwd? string
---@return string[]
M.branches = function(cwd)
  cwd = cwd or get_buffer_cwd()
  local branches =
    vim.fn.systemlist("git -C " .. vim.fn.escape(cwd, " ") .. " branch --all --format='%(refname:short)' 2>/dev/null")
  if vim.v.shell_error ~= 0 then return {} end
  return vim.tbl_filter(function(branch) return not branch:match("/HEAD$") end, branches)
end

--- Walks back from HEAD to the first commit that another branch points at, i.e. where HEAD most likely forked.
---@param cwd? string
---@return string? commit
M.fork_point = function(cwd)
  cwd = cwd or get_buffer_cwd()
  local current = git("rev-parse --abbrev-ref HEAD", cwd)
  local lines = vim.fn.systemlist(
    "git -C "
      .. vim.fn.escape(cwd, " ")
      .. " log --simplify-by-decoration --decorate-refs=refs/heads/ --decorate-refs=refs/remotes/"
      .. " --format='%H%x09%D' HEAD 2>/dev/null"
  )
  if vim.v.shell_error ~= 0 then return nil end
  for _, line in ipairs(lines) do
    local commit, refs = line:match("^(%x+)\t(.*)$")
    for ref in vim.gsplit(refs or "", ", ", { plain = true }) do
      ref = ref:gsub("^HEAD %-> ", "")
      local is_current = current and (ref == current or ref:match("/" .. vim.pesc(current) .. "$"))
      if ref ~= "" and ref ~= "HEAD" and not ref:match("/HEAD$") and not is_current then return commit end
    end
  end
end

return M
