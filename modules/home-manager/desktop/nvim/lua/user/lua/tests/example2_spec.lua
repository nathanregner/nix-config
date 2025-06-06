-- [nfnl] Compiled from fnl/tests/example2_spec.fnl by https://github.com/Olical/nfnl, do not edit.
local _local_1_ = require("nfnl.module")
local autoload = _local_1_["autoload"]
local _local_2_ = require("plenary.busted")
local describe = _local_2_["describe"]
local it = _local_2_["it"]
local h = autoload("nvim-test.helpers")
local c = autoload("nfnl.core")
c.keys(vim.g.sexp_filetypes)
c.merge(c.assoc({}, "a", "b", "c", "asdfasdfasdfasdffa"), c.assoc({}, "d", 1))
do
  local _ = (1 + 2 + 3)
end
--[[ vim.v.lpath (c.keys (require "nvim-test.helpers")) ]]
return nil
