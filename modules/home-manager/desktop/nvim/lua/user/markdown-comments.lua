-- Injection ranges come from whole nodes, so a childless comment token can't skip the
-- per-line `///` prefix. Rebuild the ranges line by line for queries that set
-- `injection.strip-prefix`, so the injected language sees the comment text only.
local LanguageTree = require("vim.treesitter.languagetree")

local original_get_injection = LanguageTree._get_injection

local function strip_prefix(source, ranges, prefix)
  if type(source) ~= "number" then return ranges end

  local pattern = "^%s*" .. vim.pesc(prefix)
  local stripped = {}
  for _, range in ipairs(ranges) do
    local srow, _, _, erow, ecol = unpack(range)
    local lines = vim.api.nvim_buf_get_lines(source, srow, erow + 1, false)
    for i, line in ipairs(lines) do
      local row = srow + i - 1
      local _, prefix_end = line:find(pattern)
      if prefix_end then
        -- Markdown treats a single space after the prefix as separator, not indentation.
        if line:sub(prefix_end + 1, prefix_end + 1) == " " then prefix_end = prefix_end + 1 end

        local row_offset = vim.api.nvim_buf_get_offset(source, row)
        local start = { row, prefix_end, row_offset + prefix_end }
        -- Non-final lines run to the next line's start so the line break stays in the text.
        local finish = row == erow and { row, ecol, row_offset + ecol }
          or { row + 1, 0, vim.api.nvim_buf_get_offset(source, row + 1) }
        if finish[3] > start[3] then
          stripped[#stripped + 1] = { start[1], start[2], start[3], finish[1], finish[2], finish[3] }
        end
      end
    end
  end
  return stripped
end

function LanguageTree:_get_injection(match, metadata)
  local lang, combined, ranges = original_get_injection(self, match, metadata)
  local prefix = metadata["injection.strip-prefix"]
  if prefix then ranges = strip_prefix(self._source, ranges, prefix) end
  return lang, combined, ranges
end
