local project_name = vim.fn.fnamemodify(vim.fn.getcwd(), ":p:h:t")
local workspace_dir = vim.fn.environ()["HOME"] .. "/.cache/jdtls/workspace/" .. project_name
local config = {
	cmd = {
		"jdtls",
		"--jvm-arg=-javaagent:" .. vim.g.nix.jdtls.lombok,
		"-data",
		workspace_dir,
	},
	root_dir = vim.fs.dirname(vim.fs.find({ "gradlew", ".git", "mvnw" }, { upward = true })[1]),
	settings = vim.g.nix.jdtls.settings,
}
require("jdtls").start_or_attach(config)
