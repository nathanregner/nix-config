---@module "lazy"
---@type LazySpec
return {
  "catppuccin/nvim",
  name = "catppuccin",
  priority = 1000,
  init = function(opts)
    require("catppuccin").setup({
      integrations = {
        treesitter = true,
      },
      flavour = "mocha",
      no_italic = true,
      highlight_overrides = {
        all = function(mocha)
          return {
            BlinkCmpKindText = { fg = mocha.subtext0 },
          }
        end,
      },
    })
    vim.cmd.colorscheme("catppuccin")
  end,
}
