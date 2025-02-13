---@module "lazy"
---@type LazySpec
return { -- https://cmp.saghen.dev/installation.html
  "saghen/blink.cmp",
  dir = vim.g.nix.blink_cmp.dir,
  pin = true,
  -- optional: provides snippets for the snippet source
  dependencies = {
    {
      "L3MON4D3/LuaSnip",
      build = "CC=clang make install_jsregexp",
      dir = vim.g.nix.luasnip.dir,
      pin = true,
      dependencies = {
        "nvim-treesitter/nvim-treesitter",
        -- https://github.com/rafamadriz/friendly-snippets
        {
          "rafamadriz/friendly-snippets",
          config = function() require("luasnip.loaders.from_vscode").lazy_load() end,
        },
      },
      config = function()
        local ls = require("luasnip")

        -- TODO
        -- ls.setup({
        --   load_ft_func = require("luasnip.extras.filetype_functions").extend_load_ft({
        --     javascript = { "ecma" },
        --     typescript = { "javascript", "ecma" },
        --     javascriptreact = { "javascript", "ecma" },
        --     typescriptreact = { "typescript", "ecma" },
        --   }),
        -- })

        -- require("user.snippets.ecma")
        -- require("user.snippets.typescriptreact")
      end,
    },
  },
  version = "*",
  ---@module 'blink.cmp'
  ---@type blink.cmp.Config
  opts = {
    -- 'default' for mappings similar to built-in completion
    -- 'super-tab' for mappings similar to vscode (tab to accept, arrow keys to navigate)
    -- 'enter' for mappings similar to 'super-tab' but with 'enter' to accept
    -- See the full "keymap" documentation for information on defining your own keymap.
    keymap = {
      preset = "super-tab",
      -- ['<C-space>'] = { 'show', 'show_documentation', 'hide_documentation' },
      ["<C-n>"] = { "select_next", "show", "show_documentation", "hide_documentation" },
      ["<C-y>"] = { "select_and_accept" },
      ["<M-k>"] = { "show_signature", "hide_signature", "fallback" },
    },
    -- TODO
    -- keymap = { preset = "default" },

    appearance = {
      -- Sets the fallback highlight groups to nvim-cmp's highlight groups
      -- Useful for when your theme doesn't support blink.cmp
      -- Will be removed in a future release
      use_nvim_cmp_as_default = true,
      -- Set to 'mono' for 'Nerd Font Mono' or 'normal' for 'Nerd Font'
      -- Adjusts spacing to ensure icons are aligned
      nerd_font_variant = "mono",
    },

    snippets = { preset = "luasnip" },

    -- Default list of enabled providers defined so that you can extend it
    -- elsewhere in your config, without redefining it, due to `opts_extend`
    sources = {
      -- add lazydev to your completion providers
      default = { "lazydev", "lsp", "path", "snippets", "buffer" },
      providers = {
        lazydev = {
          name = "LazyDev",
          module = "lazydev.integrations.blink",
          -- make lazydev completions top priority (see `:h blink.cmp`)
          score_offset = 100,
        },

        -- disable score offsets
        lsp = {
          transform_items = function(_, items)
            -- filter out text items, since we have the buffer source
            return vim.tbl_filter(
              function(item) return item.kind ~= require("blink.cmp.types").CompletionItemKind.Text end,
              items
            )
          end,
        },
        snippets = {
          score_offset = function(ctx)
            vim.notify("kw: " .. ctx.trigger.initial_kind)
            -- TODO: trigger_character: only suffix
            local trigger = ctx.trigger.initial_kind
            if trigger == "manual" then return -3 end
            return 0
          end,
        },
        buffer = {
          score_offset = function(ctx)
            local trigger = ctx.trigger.initial_kind
            if trigger ~= "trigger_character" then return -3 end
            return 0
          end,
        },
      },
    },

    fuzzy = {
      use_frecency = false,
      use_proximity = false,
      prebuilt_binaries = {
        download = false,
      },
    },
  },
  opts_extend = { "sources.default" },
}
