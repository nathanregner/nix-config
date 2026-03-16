local logged_grammars = {}

-- Monkeypatch vim.treesitter.get_parser to log all grammar loads
local original_get_parser = vim.treesitter.get_parser
vim.treesitter.get_parser = function(bufnr, lang, opts)
  local parser = original_get_parser(bufnr, lang, opts)

  if parser and lang and not logged_grammars[lang] then
    logged_grammars[lang] = true

    local state_dir = vim.fn.stdpath("state")
    local log_file = string.format("%s/treesitter-grammars-%d.log", state_dir, vim.fn.getpid())

    local uv = vim.loop
    uv.fs_open(log_file, "a", tonumber("660", 8), function(err, fd)
      if err or not fd then return end
      uv.fs_write(fd, lang .. "\n", -1, function()
        uv.fs_close(fd, function() end)
      end)
    end)
  end

  return parser
end
