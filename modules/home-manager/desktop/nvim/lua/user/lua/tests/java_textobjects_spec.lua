local function get_captures(content, query_name)
  local bufnr = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, vim.split(content, "\n"))
  vim.bo[bufnr].filetype = "java"

  local parser = vim.treesitter.get_parser(bufnr, "java")
  local tree = parser:parse()[1]
  local root = tree:root()

  local query = vim.treesitter.query.get("java", query_name)
  local captures = {}

  for id, node in query:iter_captures(root, bufnr) do
    local name = query.captures[id]
    local start_row, start_col, end_row, end_col = node:range()
    local text = vim.treesitter.get_node_text(node, bufnr)
    table.insert(captures, {
      name = name,
      text = text,
      range = { start_row, start_col, end_row, end_col },
    })
  end

  vim.api.nvim_buf_delete(bufnr, { force = true })
  return captures
end

local function filter_captures(captures, name)
  local result = {}
  for _, cap in ipairs(captures) do
    if cap.name == name then table.insert(result, cap) end
  end
  return result
end

local function unique_texts(captures)
  local seen = {}
  local result = {}
  for _, cap in ipairs(captures) do
    if not seen[cap.text] then
      seen[cap.text] = true
      table.insert(result, cap.text)
    end
  end
  return result
end

describe("java textobjects", function()
  describe("annotation parameters", function()
    it("captures single annotation parameter", function()
      local captures = get_captures(--[[ java ]]
        [[
@SuppressWarnings(value = "unchecked")
class Foo {}
]],
        "textobjects"
      )

      local inner = unique_texts(filter_captures(captures, "parameter.inner"))
      local outer = unique_texts(filter_captures(captures, "parameter.outer"))

      assert.are.same({ 'value = "unchecked"' }, inner)
      assert.are.same({ 'value = "unchecked"' }, outer)
    end)

    it("captures multiple annotation parameters", function()
      local captures = get_captures(--[[ java ]]
        [[
@RequestMapping(method = GET, path = "/api")
class Foo {}
]],
        "textobjects"
      )

      local inner = unique_texts(filter_captures(captures, "parameter.inner"))

      assert.are.same({ "method = GET", 'path = "/api"' }, inner)
    end)

    it("includes comma in outer captures for multiple parameters", function()
      local captures = get_captures(--[[ java ]]
        [[
@Annotation(first = "a", second = "b")
class Foo {}
]],
        "textobjects"
      )

      local outer = unique_texts(filter_captures(captures, "parameter.outer"))

      assert.are.same({ 'first = "a"', ",", 'second = "b"' }, outer)
    end)

    it("captures various value types", function()
      local captures = get_captures(--[[ java ]]
        [[
@JsonProperty(value = "name", required = true)
class Foo {}
]],
        "textobjects"
      )

      local inner = unique_texts(filter_captures(captures, "parameter.inner"))

      assert.are.same({ 'value = "name"', "required = true" }, inner)
    end)
  end)
end)
