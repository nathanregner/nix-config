-- [nfnl] Compiled from tests/test.fnl by https://github.com/Olical/nfnl, do not edit.
local _local_1_ = require("plenary.busted")
local describe = _local_1_["describe"]
local it = _local_1_["it"]
local before_each = _local_1_["before_each"]
local after_each = _local_1_["after_each"]
local c = autoload("nfnl.core")
local p = autoload("plenary.busted.test")
c.keys(vim.g.sexp_filetypes)
c.merge(c.assoc({}, "a", "b", "c", "asdfasdfasdfasdffa"), c.assoc({}, "d", 1))
do local _ = (1 + 2 + 3) end
local function _2_()
  error("test")
  return print("test")
end
return describe("test", it("works", _2_))
