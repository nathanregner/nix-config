local cmp = require("cmp")
local types = require("cmp.types")

local luasnip = require("luasnip")

local buffer = {
  name = "buffer",
  option = {
    get_bufnrs = function()
      -- local bufs = {}
      -- for _, win in ipairs(vim.api.nvim_list_wins()) do
      --   bufs[vim.api.nvim_win_get_buf(win)] = true
      -- end
      -- return vim.tbl_keys(bufs)
      return vim.api.nvim_list_bufs()
    end,
  },
}

local lspkind = require("lspkind")

local compare = cmp.config.compare

cmp.setup({
  completion = { completeopt = "menu,menuone,noinsert" },

  formatting = {
    format = lspkind.cmp_format({
      mode = "symbol",
      maxwidth = {
        menu = 50, -- leading text (labelDetails)
        abbr = 50, -- actual suggestion item
      },
      ellipsis_char = "...",
      show_labelDetails = true,
    }),
  },

  mapping = cmp.mapping.preset.insert({
    ["<C-n>"] = cmp.mapping(function()
      if cmp.visible() then
        cmp.select_next_item()
      else
        cmp.complete({
          config = {
            sources = {
              { name = "nvim_lsp" },
              buffer,
            },
          },
        })
      end
    end),
    -- ["<C-n>"] = cmp.mapping.select_next_item(),
    ["<C-p>"] = cmp.mapping.select_prev_item(),

    ["<C-b>"] = cmp.mapping.scroll_docs(-4),
    ["<C-f>"] = cmp.mapping.scroll_docs(4),

    ["<C-y>"] = cmp.mapping.confirm({ select = true }),
    ["<CR>"] = cmp.mapping.confirm({ select = true, behavior = cmp.ConfirmBehavior.Insert }),

    -- https://github.com/hrsh7th/nvim-cmp/wiki/Example-mappings#luasnip
    ["<Tab>"] = cmp.mapping(function(fallback)
      if cmp.visible() then
        local entry = cmp.get_selected_entry()
        if not entry then cmp.select_next_item({ behavior = cmp.SelectBehavior.Select }) end
        cmp.confirm({
          behavior = cmp.ConfirmBehavior.Replace,
          select = true,
        })
      elseif luasnip.expand_or_locally_jumpable() then
        luasnip.expand_or_jump()
      else
        fallback()
      end
    end, { "i", "s" }),

    ["<S-Tab>"] = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.select_prev_item()
      elseif luasnip.jumpable(-1) then
        luasnip.jump(-1)
      else
        fallback()
      end
    end, { "i", "s" }),
  }),

  -- For an understanding of why these mappings were
  -- chosen, you will need to read `:help ins-completion`
  --
  -- No, but seriously. Please read `:help ins-completion`, it is really good!
  snippet = {
    expand = function(args) luasnip.lsp_expand(args.body) end,
  },
  sorting = {
    priority_weight = 2,
    comparators = {
      -- cmp.config.compare.exact,
      -- cmp.config.compare.score,
      -- cmp.config.compare.recently_used,
      -- cmp.config.compare.offset,
      -- cmp.config.compare.kind,

      -- compare.score_offset, -- not good at all
      compare.exact,
      compare.locality,
      compare.recently_used,
      compare.score, -- based on :  score = score + ((#sources - (source_index - 1)) * sorting.priority_weight)
      compare.offset,
      -- compare.scopes, -- what?
      compare.sort_text,
      -- compare.kind,
    },
  },
  sources = {
    { name = "luasnip" },
    { name = "path" },
    {
      name = "nvim_lsp",
      entry_filter = function(entry, _ctx)
        local kind = types.lsp.CompletionItemKind[entry:get_kind()]
        if kind == "Text" then return false end
        return true
      end,
    },
    buffer,
  },
})

cmp.setup.cmdline("/", {
  mapping = cmp.mapping.preset.cmdline(),
  sources = {
    { name = "buffer" },
  },
})

cmp.setup.cmdline(":", {
  mapping = cmp.mapping.preset.cmdline(),
  sources = cmp.config.sources({
    { name = "path" },
  }, {
    {
      name = "cmdline",
      option = {
        ignore_cmds = { "Man", "!", "Gbrowse" },
      },
    },
  }),
})
