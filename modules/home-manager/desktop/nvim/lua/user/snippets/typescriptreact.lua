local ls = require("luasnip")
local s = ls.snippet
local sn = ls.snippet_node
local i = ls.insert_node
local d = ls.dynamic_node
local fmt = require("luasnip.extras.fmt").fmt

ls.add_snippets("typescriptreact", {
  s(
    "rfc",
    d(1, function(_, parent)
      return sn(
        nil,
        fmt(
          [[
            type {1}Props = {{
              {2}
            }}

            export function {1}(props: {1}Props) {{
              return (
                <div>
                  {3}
                </div>
              )
            }}
          ]],
          { i(1, parent.env.TM_FILENAME_BASE), i(2, ""), i(3, "") },
          { repeat_duplicates = true }
        )
      )
    end),
    { priority = 1000 }
  ), -- nil
}, {
  key = "custom/typescriptreact",
  default_priority = 1000,
})
