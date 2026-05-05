-- Auto-discover snippet modules from this directory
local uv = vim.uv or vim.loop
local snippet_dir = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":h")
local ft_modules = {} -- filetype -> list of modules

-- Files that handle multiple filetypes
local multi_ft = {
  ecma = { "javascript", "javascriptreact", "typescript", "typescriptreact" },
}

local function register(ft, module)
  ft_modules[ft] = ft_modules[ft] or {}
  table.insert(ft_modules[ft], module)
end

local handle = uv.fs_scandir(snippet_dir)
if handle then
  while true do
    local name, type = uv.fs_scandir_next(handle)
    if not name then break end

    if type == "file" then
      local basename = name:match("^(.+)%.lua$")
      if basename and basename ~= "init" and basename ~= "all" then
        local module = "user.snippets." .. basename
        for _, ft in ipairs(multi_ft[basename] or { basename }) do
          register(ft, module)
        end
      end
    end
  end
end

-- Register nix-configured extra modules (filetype -> list of modules)
for ft, modules in pairs(vim.g.nix.luasnip.extraModules or {}) do
  for _, module in ipairs(modules) do
    -- print("register", ft, module)
    register(ft, module)
  end
end

-- Load "all" snippets immediately (they apply to all filetypes)
require("user.snippets.all")

-- Lazy-load filetype-specific snippets
local group = vim.api.nvim_create_augroup("user.snippets", { clear = true })
vim.api.nvim_create_autocmd("FileType", {
  group = group,
  callback = function(ev)
    -- print("loading", ev.match)
    for _, module in ipairs(ft_modules[ev.match] or {}) do
      -- print("  loading", module)
      require(module)
    end
  end,
})
