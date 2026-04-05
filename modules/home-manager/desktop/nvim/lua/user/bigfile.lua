local M = {}

---@param bufnr number
local function get_buf_size(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local ok, stats = pcall(function() return vim.loop.fs_stat(vim.api.nvim_buf_get_name(bufnr)) end)
  if not (ok and stats) then return end
  return stats.size
end

---@param buf integer?
function M.is_big(buf) return vim.b[buf or 0].bigfile end

function M.setup()
  -- vim.print("setup")

  vim.api.nvim_create_autocmd({ "BufReadPre" }, {
    group = vim.api.nvim_create_augroup("user_bigfile", { clear = true }),
    pattern = "*",
    callback = function(ev)
      local size = get_buf_size(ev.buf)
      -- vim.print("checking " .. size)
      if size and size < 512 * 1014 then return end

      -- vim.print("biggggg")
      -- vim.cmd("syntax clear")
      vim.bo.filetype = ""
      vim.bo.syntax = "OFF"
      vim.b[ev.buf].bigfile = true
      print(vim.b[ev.buf].bigfile)
    end,
  })
end

return M
