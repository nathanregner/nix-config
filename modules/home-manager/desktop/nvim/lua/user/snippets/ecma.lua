-- fmt("for (const {} of {}) {{\n  {}\n}}", { i(1, "element"), t(node_content), isn(3, {}, "") })
-- fmt("for (const {} of {}) {{\n  {}\n}}", { i(1, "element"), t(node_content), isn(3, {}, "") })
-- fmt("for (const {} of {}) {{\n  {}\n}}", { i(1, "element"), t(node_content), isn(3, {}, "") })
-- fmt("for (const {} of {}) {{\n  {}\n}}", { i(1, "element"), t(node_content), isn(3, {}, "") })
-- require("luasnip.session.snippet_collection").clear_snippets("javascript")
-- require("luasnip.session.snippet_collection").clear_snippets("ecma") -- TODO

local ls = require("luasnip")
local s = ls.snippet
local sn = ls.snippet_node
local isn = ls.indent_snippet_node
local t = ls.text_node
local i = ls.insert_node
local f = ls.function_node
local c = ls.choice_node
local d = ls.dynamic_node
local r = ls.restore_node
local ai = require("luasnip.nodes.absolute_indexer")
local events = require("luasnip.util.events")
local extras = require("luasnip.extras")
local l = extras.lambda
local rep = extras.rep
local p = extras.partial
local m = extras.match
local n = extras.nonempty
local dl = extras.dynamic_lambda
local fmt = require("luasnip.extras.fmt").fmt
local fmta = require("luasnip.extras.fmt").fmta
local conds = require("luasnip.extras.expand_conditions")
local postfix = require("luasnip.extras.postfix").postfix
local types = require("luasnip.util.types")
local parse = require("luasnip.util.parser").parse_snippet
local ms = ls.multi_snippet
local k = require("luasnip.nodes.key_indexer").new_key

local treesitter_postfix = require("luasnip.extras.treesitter_postfix").treesitter_postfix

local ecma = {
  "javascript",
  "typescript",
  -- "javascriptreact", "typescriptreact"
}

local expression = [[
  [
    (call_expression)
    (identifier)
    (subscript_expression)
    (array)
    (number)
    (string)
    (member_expression)
    (parenthesized_expression)
  ] @prefix
]]

-- require("luasnip.session.snippet_collection").clear_snippets("javascript") -- TODO

-- ls.filetype_extend("ecma", { "javascript", "typescript", "javascriptreact", "typescriptreact" })
ls.filetype_extend("javascript", { "ecma" })

ls.add_snippets("ecma", {
  -- s("el", fmt("<%= {} %>{}", { i(1), i(0) })),
  -- s("log", fmt("console.log({})"), { i(1) }),
  treesitter_postfix({
    trig = ".clv",
    matchTSNode = {
      query = [[
        [
          (identifier)
        ] @prefix
      ]],
      query_lang = "javascript",
    },
    reparseBuffer = "live",
    override_priority = 1000,
  }, {
    d(1, function(_, parent)
      local match = parent.snippet.env.LS_TSMATCH
      return sn(nil, fmt("console.log('{1}', {1});", { t(match) }))
    end),
  }),
  treesitter_postfix({
    trig = ".cl",
    matchTSNode = {
      query = expression,
      query_lang = "javascript",
    },
    reparseBuffer = "live",
    override_priority = 1000,
  }, {
    d(1, function(_, parent)
      local match = parent.snippet.env.LS_TSMATCH
      return sn(nil, fmt("console.log({});", { t(match) }))
    end),
  }),
  treesitter_postfix({
    trig = ".forof",
    matchTSNode = {
      query = expression,
      query_lang = "javascript",
    },
    reparseBuffer = "live",
    override_priority = 1000,
  }, {
    d(1, function(_, parent)
      local match = parent.snippet.env.LS_TSMATCH
      return sn(nil, fmt("for (const {} of {}) {{\n  {}\n}}", { i(1, "iterator"), t(match), i(2, {}, "") }))
    end), -- nil
  }),
}, {
  key = "ecma-custom",
})
