---@module "lazy"
---@type LazySpec
return {
  "nvim-treesitter/nvim-treesitter-textobjects",
  dependencies = { "nvim-treesitter/nvim-treesitter" },
  branch = "main",
  ---@type TSTextObjects.UserConfig
  opts = {
    move = { set_jumps = true },
    select = { lookahead = true },
  },
  init = function()
    -- Disable entire built-in ftplugin mappings to avoid conflicts.
    -- See https://github.com/neovim/neovim/tree/master/runtime/ftplugin for built-in ftplugins.
    vim.g.no_plugin_maps = true
  end,
  config = function(a, opts)
    -- require("nvim-treesitter-textobjects").setup(opts)
    local ts_repeat_move = require("nvim-treesitter-textobjects.repeatable_move")

    -- vim way: ; goes to the direction you were moving.
    vim.keymap.set({ "n", "x", "o" }, ";", ts_repeat_move.repeat_last_move)
    vim.keymap.set({ "n", "x", "o" }, ",", ts_repeat_move.repeat_last_move_opposite)

    -- make builtin f, F, t, T also repeatable with ; and ,
    vim.keymap.set({ "n", "x", "o" }, "f", ts_repeat_move.builtin_f_expr, { expr = true })
    vim.keymap.set({ "n", "x", "o" }, "F", ts_repeat_move.builtin_F_expr, { expr = true })
    vim.keymap.set({ "n", "x", "o" }, "t", ts_repeat_move.builtin_t_expr, { expr = true })
    vim.keymap.set({ "n", "x", "o" }, "T", ts_repeat_move.builtin_T_expr, { expr = true })

    -- select
    for k, v in pairs({
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
    }) do
      vim.keymap.set(
        { "x", "o" },
        k,
        function() require("nvim-treesitter-textobjects.select").select_textobject(v, "textobjects") end
      )
    end

    -- swap
    local swap = require("nvim-treesitter-textobjects.swap")
    vim.keymap.set("n", "<leader>a", function() swap.swap_next("@parameter.inner") end)
    vim.keymap.set("n", "<leader>A", function() swap.swap_previous("@parameter.inner") end)

    -- move
    local move = require("nvim-treesitter-textobjects.move")
    for k, v in pairs({
      a = "@parameter.outer",
      f = "@function.outer",
      t = "@tag.outer",
    }) do
      local modes = { "n", "x", "o" }
      vim.keymap.set(modes, "]" .. k, function() move.goto_next_start(v, "textobjects") end)
      vim.keymap.set(modes, "[" .. k, function() move.goto_previous_start(v, "textobjects") end)
      vim.keymap.set(modes, "]" .. string.upper(k), function() move.goto_next_end(v, "textobjects") end)
      vim.keymap.set(modes, "[" .. string.upper(k), function() move.goto_previous_end(v, "textobjects") end)
    end

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
}
