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

local tfnr = function(attr, modifiers)
  return {
    t({ attr, modifiers .. " fn " }),
    i(1, "feature"),
    t("() -> "),
    d(2, function()
      local patterns = {
        { vim.regex("anyhow"), "anyhow::Result<()>" },
        { vim.regex("eyre"), "eyre::Result<()>" },
      }

      local query = vim.treesitter.query.parse(
        "rust",
        [[
          (scoped_type_identifier
            path: (identifier) @identifier)
        ]]
      )

      local tree = vim.treesitter.get_parser(0, "rust"):parse()[1]
      for _id, node, _metadata in query:iter_captures(tree:root(), 0) do
        local text = vim.treesitter.get_node_text(node, vim.api.nvim_get_current_buf())
        for _, pattern in ipairs(patterns) do
          local re, sub = pattern[1], pattern[2]
          if re:match_str(text) then return sn(nil, t(sub)) end
        end
      end

      local choices = { t("Result<(), Box<dyn Error>>") }
      for _, pattern in ipairs(patterns) do
        table.insert(choices, t(pattern[2]))
      end
      return sn(nil, c(1, choices))
    end),
    t({ " {", "" }),
    i(3),
    t({ "    Ok(())", "}" }),
  }
end

ls.add_snippets("rust", {
  s("tfnr", tfnr("#[test]", "")),
  s("ttfn", {
    t({ "#[tokio::test]", "async fn " }),
    i(1, "feature"),
    t({ "() {", "" }),
    i(2),
    t("}"),
  }),
  s("ttfnr", tfnr("#[tokio::test]", "async ")),
  s("wpfn", {
    t({ "fn " }),
    i(1, "parser"),
    t({ "(input: &mut &str) -> ModalResult<" }),
    i(2, "()"),
    t({ "> {", "" }),
    i(3, "    rest"),
    t({ ".parse_next(input)", "}" }),
  }),
}, {
  key = "user.rust",
  -- key = "__autosnippets__" .. ft .. "__" .. filename,
})
