local cmp = require("cmp")
local types = require("cmp.types")

local luasnip = require("luasnip")

---@type cmp.SourceConfig
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
  ---@param entry cmp.Entry
  ---@param ctx cmp.Context
  entry_filter = function(entry, ctx)
    if #entry.word > 100 then return false end
    return true
  end,
}

---@type cmp.SourceConfig
local lsp = {
  name = "nvim_lsp",
  entry_filter = function(entry, _ctx)
    local kind = types.lsp.CompletionItemKind[entry:get_kind()]
    if kind == "Text" then return false end
    return true
  end,
}

local lspkind = require("lspkind")

local compare = cmp.config.compare

---@param entry cmp.Entry
local is_emmet_snippet = function(entry)
  return entry.source.source.client and entry.source.source.client.name == "emmet_language_server"
end

---offset: Entries with smaller offset will be ranked higher.
---@type cmp.ComparatorFunction
local penalize_emmet = function(entry1, entry2)
  -- if
  --   entry1.completion_item.kind == types.lsp.CompletionItemKind.Snippet
  --   and entry2.completion_item.kind == types.lsp.CompletionItemKind.Snippet
  -- then
  --   if is_emmet_snippet(entry1) and not is_emmet_snippet(entry2) then return false end
  --   if is_emmet_snippet(entry2) and not is_emmet_snippet(entry1) then return true end
  -- end
  return nil
end

cmp.setup({
  completion = { completeopt = "menu,menuone,noinsert" },

  formatting = {
    format = lspkind.cmp_format({
      -- mode = "symbol",
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
          reason = "manual",
          ---@type cmp.ConfigSchema
          config = {
            sources = {
              lsp,
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
      -- penalize_emmet,
      compare.exact,
      compare.score, -- based on :  score = score + ((#sources - (source_index - 1)) * sorting.priority_weight)
      compare.locality,
      compare.recently_used,
      compare.offset,
      compare.sort_text,
    },
  },
  sources = {
    { name = "luasnip" },
    { name = "path" },
    lsp,
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
