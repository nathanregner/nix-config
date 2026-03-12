describe("nix_fetch", function()
  local nix_fetch = require("user.gx.nix_fetch")

  local function test_with_content(content, cursor_line)
    local bufnr = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, vim.split(content, "\n"))
    vim.bo[bufnr].filetype = "nix"
    vim.api.nvim_set_current_buf(bufnr)
    vim.api.nvim_win_set_cursor(0, { cursor_line, 5 })

    local result = nix_fetch.handle()

    vim.api.nvim_buf_delete(bufnr, { force = true })

    return result
  end

  it("extracts URL with simple string tag", function()
    local result = test_with_content(
      -- nix
      [[
        {
          src = fetchFromGitHub {
            owner = "nixos";
            repo = "nix";
            tag = "v1.0.0";
            hash = "sha256-abc123";
          };
        }
      ]],
      3
    )
    assert.are.equal("https://github.com/nixos/nix/tree/v1.0.0", result)
  end)

  it("excludes interpolated tag from URL", function()
    local result = test_with_content(
      -- nix
      [[
        rec {
          version = "1.0.0";
          src = fetchFromGitHub {
            owner = "nixos";
            repo = "nix";
            tag = "v${version}";
            hash = "sha256-abc123";
          };
        }
      ]],
      8
    )
    assert.are.equal("https://github.com/nixos/nix", result)
  end)

  it("handles missing tag", function()
    local result = test_with_content(
      -- nix
      [[
        {
          src = fetchFromGitHub {
            owner = "test-owner";
            repo = "test-repo";
            hash = "sha256-abc123";
          };
        }
      ]],
      6
    )
    assert.are.equal("https://github.com/test-owner/test-repo", result)
  end)
end)
