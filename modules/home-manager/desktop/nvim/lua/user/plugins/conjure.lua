---@module "lazy"
---@type LazySpec
return {
  "Olical/conjure",
  branch = "main",
  lazy = true,
  dependencies = {
    -- https://github.com/guns/vim-sexp
    "guns/vim-sexp",
    -- https://github.com/tpope/vim-sexp-mappings-for-regular-people
    "tpope/vim-sexp-mappings-for-regular-people",
    --[[ {
      "PaterJason/cmp-conjure",
      config = function()
        local cmp = require("cmp")
        local config = cmp.get_config()
        table.insert(config.sources, {
          name = "buffer",
          option = {
            sources = {
              { name = "conjure" },
            },
          },
        })
        cmp.setup(config)
      end,
    }, ]]
  },
  config = function(_)
    require("conjure.main").main()
    require("conjure.mapping")["on-filetype"]()
  end,
  init = function()
    vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
      pattern = { "conjure-log-*" },
      callback = function(ev) vim.diagnostic.enable(false, { bufnr = ev.buf }) end,
    })
    vim.g["conjure#extract#tree_sitter#enabled"] = true
    vim.g["conjure#client#clojure#nrepl#refresh#backend"] = "clj-reload"
    -- Rebind from K
    vim.g["conjure#mapping#doc_word"] = "gk"
    -- Fix Babashka pprint: https://github.com/Olical/conjure/issues/406
    vim.g["conjure#client#clojure#nrepl#eval#print_function"] = "cider.nrepl.pprint/pprint"
    -- Disable REPL auto-start
    vim.g["conjure#client_on_load"] = false
    vim.g["conjure#log#hud#ignore_low_priority"] = true
  end,
}
