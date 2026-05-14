local function get_captures(content, query_name)
  local bufnr = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, vim.split(content, "\n"))
  vim.bo[bufnr].filetype = "typescript"

  local parser = vim.treesitter.get_parser(bufnr, "typescript")
  local tree = parser:parse()[1]
  local root = tree:root()

  local query = vim.treesitter.query.get("typescript", query_name)
  local captures = {}

  for id, node in query:iter_captures(root, bufnr) do
    local name = query.captures[id]
    local text = vim.treesitter.get_node_text(node, bufnr)
    table.insert(captures, {
      name = name,
      text = text,
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

describe("typescript textobjects", function()
  describe("type parameters", function()
    it("captures single type parameter", function()
      local captures = get_captures([[function identity<T>() {}]], "textobjects")

      local inner = unique_texts(filter_captures(captures, "parameter.inner"))
      local outer = unique_texts(filter_captures(captures, "parameter.outer"))

      assert.are.same({ "T" }, inner)
      assert.are.same({ "T" }, outer)
    end)

    it("captures type parameter with constraint", function()
      local captures = get_captures([[function foo<T extends string>() {}]], "textobjects")

      local inner = unique_texts(filter_captures(captures, "parameter.inner"))

      assert.are.same({ "T extends string" }, inner)
    end)

    it("captures multiple type parameters", function()
      local captures = get_captures([[function pair<T, U>() {}]], "textobjects")

      local inner = unique_texts(filter_captures(captures, "parameter.inner"))

      assert.are.same({ "T", "U" }, inner)
    end)

    it("includes comma in outer captures for multiple parameters", function()
      local captures = get_captures([[function triple<A, B, C>() {}]], "textobjects")

      local outer = unique_texts(filter_captures(captures, "parameter.outer"))

      assert.are.same({ "A", ",", "B", "C" }, outer)
    end)

    it("captures type parameters with constraints", function()
      local captures =
        get_captures([[function constrained<TData extends object, TError extends Error>() {}]], "textobjects")

      local inner = unique_texts(filter_captures(captures, "parameter.inner"))

      assert.are.same({ "TData extends object", "TError extends Error" }, inner)
    end)

    it("captures type alias type parameters", function()
      local captures = get_captures([[type Box<T> = { value: T };]], "textobjects")

      local inner = unique_texts(filter_captures(captures, "parameter.inner"))

      assert.are.same({ "T" }, inner)
    end)

    it("captures interface type parameters", function()
      local captures = get_captures([[interface Container<T extends object> { value: T; }]], "textobjects")

      local inner = unique_texts(filter_captures(captures, "parameter.inner"))

      assert.are.same({ "T extends object" }, inner)
    end)

    it("captures class type parameters", function()
      local captures = get_captures([[class Box<T, U extends T> {}]], "textobjects")

      local inner = unique_texts(filter_captures(captures, "parameter.inner"))

      assert.are.same({ "T", "U extends T" }, inner)
    end)
  end)
end)
