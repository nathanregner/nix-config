-- disable netrw
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

vim.opt.diffopt = "internal,filler,closeoff,indent-heuristic,linematch:60,algorithm:histogram"

vim.opt.wrap = false

vim.diagnostic.config({
  virtual_text = { current_line = true },
})

vim.opt.listchars = "tab:\\t,extends:>,precedes:<,trail:·"

-- auto-reload files when modified externally
-- https://unix.stackexchange.com/a/383044
vim.o.autoread = true
vim.api.nvim_create_autocmd({ "BufEnter", "CursorHold", "CursorHoldI", "FocusGained" }, {
  command = "if mode() !~ '\v(c|r.?|!|t)' && getcmdwintype() == '' | checktime | endif",
  pattern = { "*" },
})
vim.api.nvim_create_autocmd({ "FileChangedShellPost" }, {
  pattern = "*",
  callback = function()
    local filepath = vim.fn.expand("%:.")
    -- bail if file no longer exists (seems to trigger repeatedly)
    if vim.fn.filereadable(filepath) == 0 then return end
    vim.notify("Reloaded " .. filepath, vim.log.levels.INFO, {})
  end,
})

-- suppress swap file warnings
vim.opt.shortmess:append("A")

vim.g.fugitive_legacy_commands = 0

require("user.treesitter")
require("user.shada").setup()

---@param spec LazyPluginSpec
---@return LazyPluginSpec
function nix_spec(spec)
  local name = vim.fs.basename(spec[1])
  if name == nil then return spec end

  local nix = vim.g.nix[string.lower(name)]
  if nix == nil then
    vim.notify("Nix plugin not found " .. name, vim.log.levels.WARN)
    return spec
  end

  spec.dir = nix.dir
  spec.pin = true
  spec.opts = vim.tbl_deep_extend("error", nix.opts or {}, spec.opts or {})
  return spec
end

function make_repeatable_move_pair(forward, backward)
  local ts_repeat_move = require("nvim-treesitter-textobjects.repeatable_move")
  local move_fn = ts_repeat_move.make_repeatable_move(function(opts)
    if opts.forward then
      forward()
    else
      backward()
    end
  end)
  return function() move_fn({ forward = true }) end, function() move_fn({ forward = false }) end
end

local bigfile = require("user.bigfile")
bigfile.setup()

-- https://github.com/folke/lazy.nvim#-plugin-spec
require("lazy").setup({
  { import = "user.plugins" },
}, {
  dev = {
    path = "~/dev/github",
  },
  change_detection = {
    enabled = false,
  },
  performance = {
    rtp = { paths = vim.g.nix.rtp },
  },
})

-- [[ Setting options ]]
-- See `:help vim.o`
-- NOTE: You can change these options as you wish!

-- Make line numbers default
vim.wo.number = true

-- Enable mouse mode
vim.o.mouse = "a"

-- Enable break indent
vim.o.breakindent = true

-- Save undo history
vim.o.undofile = true

-- Case-insensitive searching UNLESS \C or capital in search
vim.o.ignorecase = true
vim.o.smartcase = true

-- Keep signcolumn on by default
vim.wo.signcolumn = "yes"

-- Decrease update time
vim.o.updatetime = 250
vim.o.timeoutlen = 300

-- Set completeopt to have a better completion experience
vim.o.completeopt = "menuone,noselect"

-- NOTE: You should make sure your terminal supports this
vim.o.termguicolors = true

vim.o.foldcolumn = "0"
vim.o.foldlevel = 99 -- ufo needs a large value
vim.o.foldlevelstart = 99
vim.o.foldenable = true

-- [[ Basic Keymaps ]]

-- Keymaps for better default experience
-- See `:help vim.keymap.set()`
vim.keymap.set({ "n", "v" }, "<Space>", "<Nop>", { silent = true })

-- Remap for dealing with word wrap
vim.keymap.set("n", "k", "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })
vim.keymap.set("n", "j", "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })

-- Remap record macro to prevent accidental presses
vim.keymap.set("n", "<leader>q", "q", { noremap = true })
vim.keymap.set("n", "q", "<nop>", { noremap = true })

-- Diff view
vim.keymap.set({ "n", "v" }, "<leader>hp", ":diffput<cr>", { noremap = true })
vim.keymap.set({ "n", "v" }, "<leader>hg", ":diffget<cr>", { noremap = true })
vim.keymap.set("n", "<leader>hG", ":1,$+1diffget<cr>", { noremap = true })
vim.keymap.set("n", "q", "<nop>", { noremap = true })

-- Search highlight
vim.keymap.set("n", "<Esc>", "<cmd>nohls<cr>", { silent = true, noremap = true })

-- Diagnostic keymaps

vim.keymap.set("n", "<leader>sv", function()
  -- source: https://github.com/creativenull
  for name, _ in pairs(package.loaded) do
    if name:match("^user") then package.loaded[name] = nil end
  end
  dofile(vim.env.MYVIMRC)
  vim.notify("Config reloaded", vim.log.levels.INFO)
end, { desc = "[S]ource [V]imrc" })

if vim.fn.has("mac") == 1 then
  vim.g.open_cmd = "open"
elseif vim.fn.has("unix") == 1 then
  vim.g.open_cmd = "xdg-open"
end

-- Indentation
vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
  pattern = {
    "*.css",
    "*.gql",
    "*.graphql",
    "*.html",
    "*.js",
    "*.json",
    "*.jsx",
    "*.less",
    "*.sass",
    "*.scss",
    "*.ts",
    "*.tsx",
    "*.yaml",
    "*.yml",
  },
  callback = function()
    vim.bo.tabstop = 2
    vim.bo.softtabstop = 2
    vim.bo.shiftwidth = 2
  end,
})

-- https://neovim.discourse.group/t/how-to-add-custom-filetype-detection-to-various-env-files/4272/3
vim.filetype.add({
  -- Detect and assign filetype based on the extension of the filename
  extension = {
    mdx = "mdx",
    log = "log",
    conf = "conf",
    env = "sh",
    ss = "selfie_snapshot",
    x = "ld",
  },
  -- Detect and apply filetypes based on the entire filename
  filename = {
    [".env"] = "dotenv",
    ["tsconfig.json"] = "jsonc",
  },
  -- Detect and apply filetypes based on certain patterns of the filenames
  pattern = {
    -- INFO: Match filenames like - ".env.example", ".env.local" and so on
    ["%.env%.[%w_.-]+"] = "dotenv",
  },
})

-- for GBrowse, now that netrw is disabled
vim.api.nvim_create_user_command(
  "Browse",
  function(opts) vim.fn.jobstart(vim.g.open_cmd .. " " .. vim.fn.shellescape(opts.fargs[1]), { detach = true }) end,
  { nargs = 1 }
)

-- [[ Highlight on yank ]]
-- See `:help vim.highlight.on_yank()`
local highlight_group = vim.api.nvim_create_augroup("YankHighlight", { clear = true })
vim.api.nvim_create_autocmd("TextYankPost", {
  callback = function() vim.highlight.on_yank() end,
  group = highlight_group,
  pattern = "*",
})

-- Allow devshells to override makeprg via MAKEPRG env var
if vim.env.MAKEPRG then vim.o.makeprg = vim.env.MAKEPRG end

-- The line beneath this is called `modeline`. See `:help modeline`
-- vim: ts=2 sts=2 sw=2 et
