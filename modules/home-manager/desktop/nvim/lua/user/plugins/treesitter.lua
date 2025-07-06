---@module "lazy"
---@type LazySpec
return {
  {
    -- Highlight, edit, and navigate code
    "nvim-treesitter/nvim-treesitter",
    dir = vim.g.nix.nvim_treesitter.dir,
    pin = true,
    -- FIXME: load after?
    dependencies = {
      "nvim-treesitter/nvim-treesitter-textobjects",
    },
    lazy = false,
    opts = {
      parser_install_dir = vim.g.nix.nvim_treesitter.parser_install_dir,
      auto_install = true,
      highlight = { enable = true },
      indent = { enable = true },
      disable = function(_lang, buf)
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
      textobjects = {
        select = {
          enable = true,
          lookahead = true, -- Automatically jump forward to textobj, similar to targets.vim
          keymaps = {
            -- You can use the capture groups defined in textobjects.scm
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
        swap = {
          enable = true,
          swap_next = {
            ["<leader>a"] = "@parameter.inner",
          },
          swap_previous = {
            ["<leader>A"] = "@parameter.inner",
          },
        },

        lsp_interop = {
          enable = true,
          peek_definition_code = {
            ["<leader>kf"] = "@function.outer",
            ["<leader>dt"] = "@class.outer",
          },
        },
      },
    },
    config = function(_, opts)
      require("nvim-treesitter.configs").setup(opts)

      local ts_repeat_move = require("nvim-treesitter.textobjects.repeatable_move")

      -- vim way: ; goes to the direction you were moving.
      vim.keymap.set({ "n", "x", "o" }, ";", ts_repeat_move.repeat_last_move)
      vim.keymap.set({ "n", "x", "o" }, ",", ts_repeat_move.repeat_last_move_opposite)

      -- Optionally, make builtin f, F, t, T also repeatable with ; and ,
      vim.keymap.set({ "n", "x", "o" }, "f", ts_repeat_move.builtin_f_expr, { expr = true })
      vim.keymap.set({ "n", "x", "o" }, "F", ts_repeat_move.builtin_F_expr, { expr = true })
      vim.keymap.set({ "n", "x", "o" }, "t", ts_repeat_move.builtin_t_expr, { expr = true })
      vim.keymap.set({ "n", "x", "o" }, "T", ts_repeat_move.builtin_T_expr, { expr = true })
    end,
  },
  {
    -- "mtrajano/tssorter.nvim",
    "nathanregner/tssorter.nvim",
    keys = function()
      return {
        { "<leader>st", function() require("tssorter").sort({ range = "paragraph" }) end, desc = "[S]ort [t]ree" },
        { "<leader>sT", require("tssorter").sort, desc = "[S]ort full [t]ree" },
      }
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
                "sources",
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
    "nvim-treesitter/nvim-treesitter-context",
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    lazy = false,
    keys = {
      {
        "[C",
        function() require("treesitter-context").go_to_context(vim.v.count1) end,
        silent = true,
      },
    },
    opts = {
      enable = true,
      max_lines = 10,
      mode = "cursor",
      multiline_threshold = 1,
      multiwindow = true,
    },
  },
  {
    "nathanregner/nvim-ts-autotag", -- TODO
    opts = {},
  },
}
