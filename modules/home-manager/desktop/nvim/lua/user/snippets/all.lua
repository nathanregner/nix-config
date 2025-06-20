local ls = require("luasnip")
local ms = ls.multi_snippet
local t = ls.text_node
local i = ls.insert_node
local excond = require("luasnip.extras.expand_conditions")

ls.add_snippets("all", {
  ms({
    common = { name = "shebang" },
    {
      trig = "#!",
      regTrig = false,
      snippetType = "autosnippet",
      condition = excond.line_begin,
    },
    { trig = "shebang", show_condition = function(line_to_cursor) return line_to_cursor == "s" end },
  }, {
    t("#!/usr/bin/env "),
    i(1, "bash"),
  }),
}, {
  key = "user.all",
  -- key = "__autosnippets__" .. ft .. "__" .. filename,
})
