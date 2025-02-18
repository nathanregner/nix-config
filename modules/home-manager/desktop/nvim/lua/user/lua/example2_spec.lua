-- [nfnl] Compiled from fnl/example2_spec.fnl by https://github.com/Olical/nfnl, do not edit.
local _local_1_ = require("nfnl.module")
local autoload = _local_1_["autoload"]
local _local_2_ = require("plenary.busted")
local describe = _local_2_["describe"]
local it = _local_2_["it"]
local c = autoload("nfnl.core")
local h = require("nvim-test.helpers")
c.assoc(h, "options", {})
c.assoc(h, "api", {nvim_get_api_info = vim.fn.api_info, nvim_exec_lua = vim.fn.exec_lua})
h.clear()
c.keys(vim.g.sexp_filetypes)
c.merge(c.assoc({}, "a", "b", "c", "asdfasdfasdfasdffa"), c.assoc({}, "d", 1))
--[[ (do h.options) (h.clear) "
    test
    test
    test
    test
    test
    test

    test
    test
    test
    test
    test
    test
    test
  " (c.keys (require "nvim-test.helpers")) ]]
return (1 + 2 + 3)
