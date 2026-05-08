local M = {}

local log_file = "/tmp/nvim-debug.log"

function M.create(prefix)
  return function(msg)
    local f = io.open(log_file, "a")
    if f then
      f:write(os.date("%H:%M:%S") .. " [" .. prefix .. "] " .. msg .. "\n")
      f:close()
    end
  end
end

return M
