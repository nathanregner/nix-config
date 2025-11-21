-- https://cmp.saghen.dev/installation.html-

local bufname_blacklist = vim.regex([[conjure-log-.*]])

-- local log_once = (function()
--   local logged = {}
--   return function(msg)
--     if not msg or logged[msg] then return end
--     logged[msg] = true
--
--     vim.print(msg)
--   end
-- end)()

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

    appearance = {
      use_nvim_cmp_as_default = true,
      -- Set to 'mono' for 'Nerd Font Mono' or 'normal' for 'Nerd Font'
      -- Adjusts spacing to ensure icons are aligned
      nerd_font_variant = "mono",
    },

    snippets = { preset = "luasnip" },

    completion = {
      trigger = {
        show_on_blocked_trigger_characters = {},
      },
    },

    cmdline = {
      completion = { menu = { auto_show = true } },
    },

    -- completion = {
    --   documentation = {
    --     auto_show = true,
    --     auto_show_delay_ms = 100,
    --     window = {
    --       border = "padded",
    --     },
    --   },
    -- },

    signature = {
      enabled = true,
    },

    -- Default list of enabled providers defined so that you can extend it
    -- elsewhere in your config, without redefining it, due to `opts_extend`
    sources = {
      -- add lazydev to your completion providers
      default = { "lazydev", "snippets", "lsp", "path", "buffer" },
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
                  return buftype == "" or bufname_blacklist:match_str(bufname) ~= nil
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

        -- snippets = {
        --   score_offset = function(ctx)
        --     vim.notify("kw: " .. ctx.trigger.initial_kind)
        --     -- TODO: trigger_character: only suffix
        --     local trigger = ctx.trigger.initial_kind
        --     if trigger == "manual" then return -3 end
        --     return 1
        --   end,
        -- },
      },
    },

    fuzzy = {
      implementation = "rust",
      prebuilt_binaries = {
        download = false,
      },
      sorts = {
        function(a, b)
          if a.source_id == "snippets" and b.source_id == "buffer" then return true end
          if a.source_id == "buffer" and b.source_id == "snippets" then return false end
          if a.source_id == "snippets" and b.source_id == "emmet_language_server" then return true end
          if a.client_name == "emmet_language_server" and b.source_id == "snippets" then return false end
        end,
        -- default sorts
        "score",
        "sort_text",
      },
    },
  },
  -- opts_extend = { "sources.default" },
})
