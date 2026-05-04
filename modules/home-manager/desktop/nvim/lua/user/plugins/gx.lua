---@module "lazy"
---@type LazySpec
return {
  "chrishrb/gx.nvim",
  dependencies = { "nvim-lua/plenary.nvim" },
  keys = { { "gx", "<cmd>Browse<cr>", mode = { "n", "x" } } },
  cmd = { "Browse" },
  init = function() vim.g.netrw_nogx = 1 end,
  opts = {
    open_browser_app = vim.g.open_cmd,
    handlers = {
      plugin = true,
      github = true,
      package_json = true,
      search = {
        name = "search",
        handle = function(mode, line, opts)
          -- don't search unless selected
          if mode == "v" then return require("gx.handlers.search").handle(mode, line, opts) end
        end,
      },
      url = {
        name = "url",
        handle = function(mode, line, _)
          -- don't open URLs without a protocol
          local pattern = "(https?://[a-zA-Z%d_/%%%-%.~@\\+#=?&:]+)"
          return require("gx.helper").find(line, mode, pattern)
        end,
      },
      jira = {
        name = "jira",
        handle = function(mode, line, _)
          local jira_domain = vim.g.jira_domain
          if not jira_domain then return end

          local ticket = require("gx.helper").find(line, mode, "(%u+-%d+)")
          if ticket and #ticket < 20 then return "https://" .. jira_domain .. "/browse/" .. ticket end
        end,
      },
      flake_inputs = {
        name = "flake_inputs",
        -- filename = "flake.nix",
        handle = function(mode, line, _)
          -- https://nixos-and-flakes.thiscute.world/other-usage-of-flakes/inputs
          local owner_repo, ref = string.match(line, '"github:([^/]+/[^/]+/?)([^/]*)"')
          if owner_repo then
            local url = "https://github.com/" .. owner_repo
            if ref ~= "" then return url .. "tree/" .. ref end
            return url
          end
        end,
      },
      nix_fetch_github = {
        name = "nix_fetch_github",
        filetype = { "nix" },
        handle = function(_, _, _) return require("user.gx.nix_fetch").handle() end,
      },
      rust = {
        name = "rust",
        filename = "Cargo.toml",
        handle = function(mode, line, _)
          local crate = require("gx.helper").find(line, mode, "(%w+)%s-=%s")
          if crate then return "https://crates.io/crates/" .. crate end
        end,
      },
      fen = {
        handle = function(mode, line, _)
          -- local test = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"
          ---@param pattern vim.regex
          local function find(pattern)
            local i, j = pattern:match_str(line)
            if i and require("gx.helper").check_if_cursor_on_url(mode, i, j) then
              return string.sub(line, i + 1, j)
            end
          end

          local fen = find(vim.regex([[\v\c([pnbrqk1-8]+/){7}[pnbrqk1-8]+ [wb] [-qk]+ (-|(\w\d)) \d+ \d+]]))
          if fen then return "https://lichess.org/editor/" .. fen end
        end,
      },
    },
    handler_options = {
      search_engine = "google", -- you can select between google, bing, duckduckgo, ecosia and yandex
      select_for_search = false, -- if your cursor is e.g. on a link, the pattern for the link AND for the word will always match. This disables this behaviour for default so that the link is opened without the select option for the word AND link

      git_remotes = { "upstream", "origin" }, -- list of git remotes to search for git issue linking, in priority
      git_remote_push = true, -- use the push url for git issue linking,
    },
  },
}
