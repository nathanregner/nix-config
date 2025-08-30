local cmp = require("cmp")
local types = require("cmp.types")

local luasnip = require("luasnip")

---@type cmp.SourceConfig
local buffer = {
  name = "buffer",
  option = {
    get_bufnrs = function()
      local bufs = {}
      for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        vim.print("consider buffer" .. buf)

        if !vim.api.nvim_buf_is_loaded(buf) then
          vim.print("skip unloaded buffer" .. buf)
          goto continue
        end

        -- don't index large files
        local byte_size = vim.api.nvim_buf_get_offset(buf, vim.api.nvim_buf_line_count(buf))
        if byte_size > 5 * 1024 * 1024 then
          vim.print("skip large buffer " .. buf)
          goto continue
        end

        -- skip neotest buffers (results in many index out bounds errors?)
        local filetype = vim.api.nvim_buf_get_option(buf, "filetype")
        if string.match(filetype, "neotest.*") then
          vim.print("ignore buffer " .. buf)
          goto continue
        end

        ::continue::
      end
      vim.print("bufs ", vim.tbl_keys(bufs))
      return vim.tbl_keys(bufs)
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
      -- cmp.config.compare.exact,
      -- cmp.config.compare.score,
      -- cmp.config.compare.recently_used,
      -- cmp.config.compare.offset,
      -- cmp.config.compare.kind,

      -- compare.score_offset, -- not good at all
      compare.exact,
      compare.score, -- based on :  score = score + ((#sources - (source_index - 1)) * sorting.priority_weight)
      compare.locality,
      compare.recently_used,
      compare.offset,
      -- compare.scopes, -- what?
      compare.sort_text,
      -- compare.kind,
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
