local project_name = vim.fn.fnamemodify(vim.fn.getcwd(), ":p:h:t")
local workspace_dir = vim.fn.environ()["HOME"] .. "/.cache/jdtls/workspace/" .. project_name

---@type vim.lsp.ClientConfig
local config = {
  cmd = {
    "jdtls",
    "--jvm-arg=-javaagent:" .. vim.g.nix.jdtls.lombok,
    "-Dlog.level=WARNING",
    "-data",
    workspace_dir,
  },

  root_dir = vim.fs.root(0, { ".git", "mvnw", "gradlew" }),
  settings = vim.g.nix.jdtls.settings,
  ---@diagnostic disable-next-line: missing-fields
  flags = {
    debounce_text_changes = 250,
  },
  capabilities = vim.tbl_deep_extend(
    "force",
    vim.lsp.protocol.make_client_capabilities(),
    require("lsp-file-operations").default_capabilities()
  ),
}
require("jdtls").start_or_attach(config)
