local Rule = require("nvim-autopairs.rule")
local cond = require("nvim-autopairs.conds")
local npairs = require("nvim-autopairs")

npairs.setup({
  disabled_filetype = { "TelescopePrompt", "snacks_picker_input" },
  check_ts = true,
  break_undo = true,
})

-- https://github.com/windwp/nvim-autopairs/wiki/Custom-rules

-- lisp quoting
table.insert(npairs.get_rules("'")[1].not_filetypes, { "clojure", "lisp" })

-- generics
npairs.add_rule(Rule("<", ">", {
  "-html",
  "-javascriptreact",
  "-typescriptreact",
  "-xml",
}):with_pair(
  -- regex will make it so that it will auto-pair on `a<` but not `a <`
  -- The `:?:?` part makes it also work on Rust generics like `some_func::<T>()`
  cond.before_regex("%a+:?:?$", 3)
):with_move(function(opts) return opts.char == ">" end))
