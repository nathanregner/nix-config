function enable_tree_sitter() end
---@module "lazy"
---@type LazySpec
return nix_spec({
  "nvim-treesitter/nvim-treesitter",
  lazy = false,
  opts = {
    auto_install = true,
    highlight = { enable = true },
    indent = { enable = true },
  },
  config = function()
    local group = vim.api.nvim_create_augroup("treesitter-enable", { clear = true })

    vim.api.nvim_create_autocmd("FileType", {
      group = group,
      callback = function(args)
        if not vim.b[args.buf].bigfile then
          local lang = vim.treesitter.language.get_lang(args.match)
          if lang then
            if vim.treesitter.query.get(lang, "highlights") then
              vim.treesitter.start(args.buf)
            else
              vim.bo[args.buf].syntax = "on"
            end
          else
            vim.bo[args.buf].syntax = "on"
          end
        end
      end,
    })
  end,
})
