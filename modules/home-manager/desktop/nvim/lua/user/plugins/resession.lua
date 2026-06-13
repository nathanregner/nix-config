local log = require("user.log").create("resession")
local using_stdin = false

---@module "lazy"
---@type LazySpec
return {
  "stevearc/resession.nvim",
  dependencies = { "esmuellert/codediff.nvim" },
  config = function()
    local resession = require("resession")
    local codediff = require("codediff.ui.lifecycle")

    resession.setup({
      buf_filter = function(bufnr)
        for win in vim.fn.win_findbuf(bufnr) do
          local tabpage = vim.api.nvim_win_get_tabpage(win)
          if codediff.get_mode(tabpage) then return false end
        end
        return true
      end,
    })
    local function get_session_name()
      local name = vim.fn.getcwd()
      local branch = vim.trim(vim.fn.system("git branch --show-current"))
      if vim.v.shell_error == 0 then
        return name .. branch
      else
        return name
      end
    end
    vim.api.nvim_create_autocmd("StdinReadPre", {
      callback = function() using_stdin = true end,
    })
    vim.api.nvim_create_autocmd("VimEnter", {
      callback = function()
        -- Only load the session if nvim was started with no args and without reading from stdin
        if vim.fn.argc(-1) == 0 and not using_stdin then
          resession.load(get_session_name(), { dir = "dirsession", silence_errors = true })
        end
      end,
    })
    vim.api.nvim_create_autocmd("VimLeavePre", {
      callback = function()
        if resession.get_current() ~= nil then
          resession.save(get_session_name(), { dir = "dirsession", notify = false })
        end
      end,
    })
    vim.api.nvim_create_user_command(
      "Mksession",
      function() resession.save(get_session_name(), { dir = "dirsession" }) end,
      {}
    )
    vim.api.nvim_create_user_command(
      "Delsession",
      function() resession.delete(get_session_name(), { dir = "dirsession" }) end,
      {}
    )
  end,
}
