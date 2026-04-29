---@module "lazy"
---@type LazySpec
return {
  "stevearc/resession.nvim",
  config = function()
    local resession = require("resession")
    resession.setup({})
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
      callback = function() vim.g.using_stdin = true end,
    })
    vim.api.nvim_create_autocmd("VimEnter", {
      callback = function()
        -- Only load the session if nvim was started with no args and without reading from stdin
        if vim.fn.argc(-1) == 0 and not vim.g.using_stdin then
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
