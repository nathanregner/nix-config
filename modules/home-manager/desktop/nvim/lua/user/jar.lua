-- LSP servers (e.g. intellij-server) return `jar:///path/to/archive!/entry` locations for library sources,
-- which neovim has no handler for; without one the buffer stays empty and the jump fails with "Cursor position outside buffer".
vim.api.nvim_create_autocmd("BufReadCmd", {
  group = vim.api.nvim_create_augroup("user.jar", { clear = true }),
  pattern = "jar://*",
  callback = function(args)
    local archive, entry = args.match:match("^jar:/?/?(/.-)!/(.*)$")
    if not archive then return end
    archive, entry = vim.uri_decode(archive), vim.uri_decode(entry)

    local result = vim.system({ "unzip", "-p", archive, entry }, { text = true }):wait()
    if result.code ~= 0 then
      vim.notify(("failed to read %s from %s: %s"):format(entry, archive, result.stderr), vim.log.levels.ERROR)
      return
    end

    local buf = args.buf
    vim.bo[buf].modifiable = true
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(result.stdout, "\n", { plain = true }))
    vim.bo[buf].buftype = "nofile"
    vim.bo[buf].modifiable = false
    vim.bo[buf].filetype = vim.filetype.match({ filename = entry }) or ""
  end,
})
