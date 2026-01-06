---@module "lazy"
---@type LazySpec
return {
  nix_spec({
    -- Highlight, edit, and navigate code
    "nvim-treesitter/nvim-treesitter",
    lazy = false,
    opts = {
      parser_install_dir = vim.g.nix["nvim-treesitter"].parser_install_dir,
      auto_install = true,
      highlight = { enable = true },
      indent = { enable = true },
      disable = function(_, buf)
        local max_filesize = 100 * 1024 -- 100 KB
        local ok, stats = pcall(vim.loop.fs_stat, vim.api.nvim_buf_get_name(buf))
        if ok and stats and stats.size > max_filesize then return true end
        if #vim.api.nvim_buf_get_lines(0, 0, 1, false)[1] > 1000 then return true end
      end,
      incremental_selection = {
        enable = true,
        keymaps = {
          node_incremental = "v",
          node_decremental = "V",
        },
      },
    },
  }),
  {
    "nvim-treesitter/nvim-treesitter-textobjects",
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    branch = "main",
    lazy = false,
    ---@type TSTextObjects.UserConfig
    opts = {
      lsp_interop = {
        enable = true,
        peek_definition_code = {
          ["<leader>kf"] = "@function.outer",
          ["<leader>dt"] = "@class.outer",
        },
      },

      move = {
        enable = true,
        set_jumps = true, -- whether to set jumps in the jumplist
        goto_next_start = {
          ["]a"] = "@parameter.outer",
          ["]f"] = "@function.outer",
          ["]]"] = "@class.outer",
          ["]t"] = "@tag.outer",
          -- ["]z"] = { query = "@fold", query_group = "folds", desc = "Next fold" },
        },
        goto_next_end = {
          ["]A"] = "@parameter.outer",
          ["]F"] = "@function.outer",
          ["]T"] = "@tag.outer",
          ["]["] = "@class.outer",
        },
        goto_previous_start = {
          ["[a"] = "@parameter.outer",
          ["[f"] = "@function.outer",
          ["[t"] = "@tag.outer",
          ["[["] = "@class.outer",
          -- ["[z"] = { query = "@fold", query_group = "folds", desc = "Previous fold" },
        },
        goto_previous_end = {
          ["[A"] = "@parameter.outer",
          ["[F"] = "@function.outer",
          ["[T"] = "@tag.outer",
          ["[]"] = "@class.outer",
        },
      },

      select = {
        enable = true,
        lookahead = true, -- Automatically jump forward to textobj, similar to targets.vim
        keymaps = {
          ["aa"] = "@parameter.outer",
          ["ia"] = "@parameter.inner",
          ["af"] = "@function.outer",
          ["if"] = "@function.inner",
          ["aC"] = "@class.outer",
          ["iC"] = "@class.inner",
          ["ac"] = "@comment.outer",
          ["ic"] = "@comment.inner",
          ["al"] = "@loop.outer",
          ["il"] = "@loop.inner",
          ["at"] = "@tag.outer",
          ["it"] = "@tag.inner",
          ["aP"] = "@pair.outer",
          ["iP"] = "@pair.inner",
          ["ae"] = "@element.inner",
          ["aE"] = "@element.outer",
        },
      },

      swap = {
        enable = true,
        swap_next = {
          ["<leader>a"] = "@parameter.inner",
        },
        swap_previous = {
          ["<leader>A"] = "@parameter.inner",
        },
      },
    },
    config = function()
      local ts_repeat_move = require("nvim-treesitter-textobjects.repeatable_move")

      -- vim way: ; goes to the direction you were moving.
      vim.keymap.set({ "n", "x", "o" }, ";", ts_repeat_move.repeat_last_move)
      vim.keymap.set({ "n", "x", "o" }, ",", ts_repeat_move.repeat_last_move_opposite)

      -- Optionally, make builtin f, F, t, T also repeatable with ; and ,
      vim.keymap.set({ "n", "x", "o" }, "f", ts_repeat_move.builtin_f_expr, { expr = true })
      vim.keymap.set({ "n", "x", "o" }, "F", ts_repeat_move.builtin_F_expr, { expr = true })
      vim.keymap.set({ "n", "x", "o" }, "t", ts_repeat_move.builtin_t_expr, { expr = true })
      vim.keymap.set({ "n", "x", "o" }, "T", ts_repeat_move.builtin_T_expr, { expr = true })

      -- Quickfix keymaps
      local next_quickfix, prev_quickfix = make_repeatable_move_pair(vim.cmd.cnext, vim.cmd.cprev)
      vim.keymap.set("n", "]q", next_quickfix, { desc = "Go to next quickfix item" })
      vim.keymap.set("n", "[q", prev_quickfix, { desc = "Go to previous quickfix item" })
      local last_quickfix, first_quickfix = make_repeatable_move_pair(vim.cmd.clast, vim.cmd.cfirst)
      vim.keymap.set("n", "]Q", last_quickfix, { desc = "Go to last quickfix item" })
      vim.keymap.set("n", "[Q", first_quickfix, { desc = "Go to first quickfix item" })

      -- https://github.com/neovim/neovim/discussions/25588#discussioncomment-8700283
      local function pos_equal(p1, p2)
        local r1, c1 = unpack(p1)
        local r2, c2 = unpack(p2)
        return r1 == r2 and c1 == c2
      end

      local function goto_error_diagnostic(f)
        return function()
          local pos_before = vim.api.nvim_win_get_cursor(0)
          f({ severity = vim.diagnostic.severity.ERROR, wrap = true })
          local pos_after = vim.api.nvim_win_get_cursor(0)
          if pos_equal(pos_before, pos_after) then f({ wrap = true }) end
        end
      end

      local next_diag_error, prev_diag_error = make_repeatable_move_pair(
        goto_error_diagnostic(vim.diagnostic.goto_next),
        goto_error_diagnostic(vim.diagnostic.goto_prev)
      )
      vim.keymap.set("n", "]e", next_diag_error, { desc = "Go to next diagnostic" })
      vim.keymap.set("n", "[e", prev_diag_error, { desc = "Go to previous error diagnostic" })
      local next_diag, prev_diag = make_repeatable_move_pair(vim.diagnostic.goto_next, vim.diagnostic.goto_prev)
      vim.keymap.set("n", "]d", next_diag, { desc = "Go to next diagnostic" })
      vim.keymap.set("n", "[d", prev_diag, { desc = "Go to previous diagnostic" })
      vim.keymap.set("n", "<leader>e", vim.diagnostic.open_float, { desc = "Open floating diagnostic message" })
      vim.keymap.set("n", "<leader>d", vim.diagnostic.setloclist, { desc = "Open diagnostics list" })
    end,
  },
  {
    "nvim-treesitter/nvim-treesitter-context",
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    keys = {
      {
        "[C",
        function() require("treesitter-context").go_to_context(vim.v.count1) end,
        silent = true,
      },
    },
    opts = {
      max_lines = 10,
      multiline_threshold = 1,
      -- mode = "topline",
    },
  },
  {
    -- "mtrajano/tssorter.nvim",
    "nathanregner/tssorter.nvim",
    keys = function()
      -- return {
      --   { "<leader>st", function() require("tssorter").sort({ range = "paragraph" }) end, desc = "[S]ort [t]ree" },
      --   { "<leader>sT", require("tssorter").sort, desc = "[S]ort full [t]ree" },
      -- }
    end,
    opts = {
      sortables = {
        graphql = {
          argument = { node = "argument", ordinal = "name" },
          selection = { node = "selection", ordinal = "name" },

          fragments = { node = "definition", ordinal = "fragment_definition" },
          variable = { node = "variable_definition", ordinal = "name" },
          field = { node = "field_definition", ordinal = "name" },
        },
        java = {
          annotation_array = { node = "class_literal" },
          annotation_element = { node = "element_value_pair" },
          method = {
            node = "method_declaration",
            ordinal = "identifier",
            order_by = function(node1, node2)
              local bufnr = vim.api.nvim_get_current_buf()
              ---@param node TSNode
              local function method_name(node) return vim.treesitter.get_node_text(node:field("name")[1], bufnr) end
              return method_name(node1) < method_name(node2)
            end,
          },
        },
        javascript = {
          -- TODO: merge
          keys = { node = "pair" },
          shorthand = { node = "shorthand_property_identifier" },
        },
        javascriptreact = {
          keys = { node = "pair" },
          shorthand = { node = "shorthand_property_identifier" },
        },
        nix = {
          -- TODO: inherit(a) b c d;
          -- attr = { node = { "attr" } },
          attrset = { node = { "binding" } },
          formal = {
            node = { "formal" },
            order_by = function(node1, node2)
              local line1 = require("tssorter.tshelper").get_text(node1)
              local line2 = require("tssorter.tshelper").get_text(node2)
              local overrides = {}
              for index, value in ipairs({
                "self",
                "inputs",
                "inputs'",
                "outputs",
                "outputs'",
                "sources",
                "options",
                "config",
                "pkgs",
                "lib",
              }) do
                overrides[value] = index
              end

              local index1 = overrides[line1]
              local index2 = overrides[line2]
              if index1 and index2 then
                return index1 < index2
              elseif index1 then
                return true
              elseif index2 then
                return false
              else
                return line1 < line2
              end
            end,
          },
          list = { node = { "element" } },
        },
        terraform = {
          attribute = { node = "attribute", ordinal = "identifier" },
          list = { node = "expression", ordinal = "literal_value" },
        },
        toml = {
          array = { node = "string" },
          pair = { node = "pair", ordinal = "bare_key" },
          table = { node = { "table" } },
        },
        typescript = {
          keys = { node = "pair" },
        },
        typescriptreact = {
          keys = { node = "pair" },
          -- TODO: shorthand_property_identifier
        },
        yaml = {
          keys = { node = "block_mapping_pair" },
          list = { node = "block_sequence_item" },
        },
      },
      logger = {
        -- level = vim.log.levels.TRACE,
        -- outfile = "~/tssorter.log", -- nil prints to messages, or add a path to a file to output logs there
      },
    },
  },
  {
    "tronikelis/ts-autotag.nvim",
    event = "VeryLazy",
    ft = { "javascriptreact", "typescriptreact", "html", "xml" },
    opts = {},
  },
}
