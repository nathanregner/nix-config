-- TODO: https://github.com/LuaLS/lua-language-server/wiki/Configuration-File
--
require("nvim")
vim.opt.runtimepath:append(",~/.config/nvim/lua")

describe("test", function()
  it("works", function()
    --
    print("goooo")
  end)
end)
