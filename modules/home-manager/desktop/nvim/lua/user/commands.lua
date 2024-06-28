vim.api.nvim_create_user_command("JSONParse", function()
  local ts_utils = require("nvim-treesitter.ts_utils")
  local current_node = ts_utils.get_node_at_cursor()

  if not current_node or not current_node:type() == "string" then
    return
  end

  local json = ts_utils.get_node_text(current_node)[1]
  local cmd = vim.system({ "node", "-e", "console.log(JSON.parse(fs.readFileSync(0, 'utf-8')))" }, {
    stdin = json,
  })

  local result = cmd:wait()
  if result.code ~= 0 then
    vim.notify("Error parsing JSON", vim.log.levels.ERROR)
    return
  end

  local start_row, start_col, end_row, end_col = vim.treesitter.get_node_range(current_node)
  local lines = vim.split(result.stdout, "\n")
  vim.api.nvim_buf_set_text(0, start_row, start_col - 1, end_row, end_col + 1, lines)
end, { range = true })
