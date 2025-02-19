---@module "lazy"
---@type LazySpec
return { -- https://cmp.saghen.dev/installation.html
  "saghen/blink.cmp",
  dir = vim.g.nix.blink_cmp.dir,
  pin = true,
  dependencies = {
    {
      "L3MON4D3/LuaSnip",
      dir = vim.g.nix.luasnip.dir,
      pin = true,
      dependencies = {
        "nvim-treesitter/nvim-treesitter",
        {
          "rafamadriz/friendly-snippets",
          config = function() require("luasnip.loaders.from_vscode").lazy_load() end,
        },
      },
    },
  },
  version = "*",
  ---@module 'blink.cmp'
  ---@type blink.cmp.Config
  opts = {
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
      use_nvim_cmp_as_default = true,
      nerd_font_variant = "mono",
    },

    snippets = { preset = "luasnip" },

    -- https://cmp.saghen.dev/recipes
    sources = {
      default = { "lazydev", "lsp", "path", "snippets", "buffer" },

      providers = {
        buffer = {
          opts = {
            get_bufnrs = function()
              -- filter to only "normal" buffers
              return vim.tbl_filter(function(bufnr) return vim.bo[bufnr].buftype == "" end, vim.api.nvim_list_bufs())
            end,
          },
          score_offset = function(ctx)
            if #ctx.get_keyword() == 0 then return -2 end
            return 0
          end,
        },

        lazydev = {
          name = "LazyDev",
          module = "lazydev.integrations.blink",
          score_offset = 100,
        },

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
