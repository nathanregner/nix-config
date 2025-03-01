local ts_query = require("nvim-treesitter.query")
local table_list = ts_query.get_capture_matches(3, "@fetchFromGitHub", "misc", nil, "nix")
vim.print(table_list)
