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

local expression = [[
  [
    (expression)
  ] @prefix
]]

-- require("luasnip.session.snippet_collection").clear_snippets("javascript") -- TODO

-- -- ls.filetype_extend("ecma", { "javascript", "typescript", "javascriptreact", "typescriptreact" })
-- ls.filetype_extend("javascript", { "ecma" })
ls.filetype_extend("javascriptreact", { "javascript" })
-- ls.filetype_extend("typescript", { "ecma" })
ls.filetype_extend("typescriptreact", { "typescript" })

local snippets = {
  typescript = {},
  javascript = {},
}

local create_postfix = function(opts)
  for _, lang in ipairs(opts.langs or { "javascript", "typescript" }) do
    local snippet = treesitter_postfix({
      trig = opts.trig,
      matchTSNode = {
        query = opts.query,
        query_lang = lang,
      },
      reparseBuffer = "live",
    }, {
      d(1, function(_, parent)
        local match = parent.snippet.env.LS_TSMATCH
        return opts.expand(match)
      end),
    })
    table.insert(snippets[lang], snippet)
  end
end

create_postfix({
  trig = ".clv",
  query = [[
        [
          (identifier)
          (member_expression)
        ] @prefix
      ]],
  expand = function(match)
    return sn(nil, fmt("console.log('{1}', {1});", { t(match) }))
  end,
})

create_postfix({
  trig = ".cl",
  query = expression,
  expand = function(match)
    return sn(nil, fmt("console.log({1});", { t(match) }))
  end,
})

create_postfix({
  trig = ".forof",
  query = expression,
  expand = function(match)
    return sn(nil, fmt("for (const {} of {}) {{\n  {}\n}}", { i(1, "iterator"), t(match), i(2, {}, "") }))
  end,
})

create_postfix({
  trig = ".json",
  query = expression,
  expand = function(match)
    return sn(nil, fmt("JSON.stringify({}, undefined, 2)", { t(match) }))
  end,
})

for lang, lang_snippets in pairs(snippets) do
  ls.add_snippets(lang, lang_snippets, {
    key = lang .. "/custom",
    default_priority = 1000,
  })
end
