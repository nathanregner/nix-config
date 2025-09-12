-- https://cmp.saghen.dev/installation.html-

local bufname_whitelist = vim.regex([[conjure-log-.*]])

---@module "lazy"
---@type LazySpec
return nix_spec({
  "saghen/blink.cmp",
  dependencies = { "L3MON4D3/LuaSnip" },

  ---@module 'blink.cmp'
  ---@type blink.cmp.Config
  opts = {
    enabled = function() return vim.fn.reg_recording() == "" end,
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
      -- Set to 'mono' for 'Nerd Font Mono' or 'normal' for 'Nerd Font'
      -- Adjusts spacing to ensure icons are aligned
      nerd_font_variant = "mono",
    },

    snippets = { preset = "luasnip" },

    cmdline = {
      completion = { menu = { auto_show = true } },
    },

    -- Default list of enabled providers defined so that you can extend it
    -- elsewhere in your config, without redefining it, due to `opts_extend`
    sources = {
      -- add lazydev to your completion providers
      default = { "lazydev", "lsp", "path", "snippets", "buffer" },
      providers = {
        buffer = {
          enabled = true, -- even if LSP completions are available
          opts = {
            get_bufnrs = function()
              return vim
                .iter(vim.api.nvim_list_bufs())
                :filter(function(bufnr)
                  if not vim.api.nvim_buf_is_loaded(bufnr) then return false end
                  local buftype = vim.bo[bufnr].buftype
                  local bufname = vim.api.nvim_buf_get_name(bufnr)
                  return buftype == "" or bufname_whitelist:match_str(bufname) ~= nil
                end)
                :totable()
            end,
          },
          -- score_offset = function(ctx)
          --   local trigger = ctx.trigger.initial_kind
          --   if trigger ~= "trigger_character" then return -3 end
          --   return 0
          -- end,
        },

        lazydev = {
          name = "LazyDev",
          module = "lazydev.integrations.blink",
          -- make lazydev completions top priority (see `:h blink.cmp`)
          score_offset = 100,
        },

        lsp = {
          fallbacks = {},
          transform_items = function(_, items)
            -- exclude text items (duplicates buffer source)
            return vim.tbl_filter(
              function(item) return item.kind ~= require("blink.cmp.types").CompletionItemKind.Text end,
              items
            )
          end,
        },

        snippets = {
          score_offset = function(ctx)
            -- vim.notify("kw: " .. ctx.trigger.initial_kind)
            -- TODO: trigger_character: only suffix
            local trigger = ctx.trigger.initial_kind
            if trigger == "manual" then return -3 end
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
      -- sorts = {
      --   function(a, b)
      --     if (a.client_name == nil or b.client_name == nil) or (a.client_name == b.client_name) then return end
      --     return b.client_name == "emmet_ls"
      --   end,
      --   -- default sorts
      --   "score",
      --   "sort_text",
      -- },
    },
  },
  -- opts_extend = { "sources.default" },
})
