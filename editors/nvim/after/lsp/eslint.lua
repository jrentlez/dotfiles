local root_file = {
	".eslintrc",
	".eslintrc.js",
	".eslintrc.cjs",
	".eslintrc.yaml",
	".eslintrc.yml",
	".eslintrc.json",
	"eslint.config.js",
	"eslint.config.mjs",
	"eslint.config.cjs",
	"eslint.config.ts",
	"eslint.config.mts",
	"eslint.config.cts",
}

---@type vim.lsp.Config
return {
	cmd = { "vscode-eslint-language-server", "--stdio" },
	filetypes = {
		"javascript",
		"javascriptreact",
		"javascript.jsx",
		"typescript",
		"typescriptreact",
		"typescript.tsx",
		"vue",
		"svelte",
		"astro",
	},
	workspace_required = true,
	-- https://eslint.org/docs/user-guide/configuring/configuration-files#configuration-file-formats
	root_dir = function(bufnr, cb)
		local fname = vim.api.nvim_buf_get_name(bufnr)
		root_file = require("lspconfig.util").insert_package_json(root_file, "eslintConfig", fname)
		local root = vim.fs.root(fname, root_file)
		cb(root)
	end,
	-- Refer to https://github.com/Microsoft/vscode-eslint#settings-options for documentation.
	settings = {
		validate = "on",
		packageManager = nil,
		useESLintClass = false,
		experimental = {
			useFlatConfig = false,
		},
		codeActionOnSave = {
			enable = false,
			mode = "all",
		},
		format = true,
		quiet = false,
		onIgnoredFiles = "off",
		rulesCustomizations = {},
		run = "onType",
		problems = {
			shortenToSingleLine = false,
		},
		-- nodePath configures the directory in which the eslint server should start its node_modules resolution.
		-- This path is relative to the workspace folder (root dir) of the server instance.
		nodePath = "",
		-- use the workspace folder location or the file location (if no workspace folder is open) as the working directory
		workingDirectory = { mode = "location" },
		codeAction = {
			disableRuleComment = {
				enable = true,
				location = "separateLine",
			},
			showDocumentation = {
				enable = true,
			},
		},
	},
	before_init = function(params, config)
		-- The "workspaceFolder" is a VSCode concept. It limits how far the
		-- server will traverse the file system when locating the ESLint config
		-- file (e.g., .eslintrc).
		config.settings.workspaceFolder = {
			uri = params.rootUri,
			name = vim.fn.fnamemodify(params.rootPath, ":t"),
		}

		-- Support flat config
		if
			vim.fn.filereadable(vim.fs.joinpath(params.rootPath, "/eslint.config.js")) == 1
			or vim.fn.filereadable(vim.fs.joinpath(params.rootPath, "/eslint.config.mjs")) == 1
			or vim.fn.filereadable(vim.fs.joinpath(params.rootPath, "/eslint.config.cjs")) == 1
			or vim.fn.filereadable(vim.fs.joinpath(params.rootPath, "/eslint.config.ts")) == 1
			or vim.fn.filereadable(vim.fs.joinpath(params.rootPath, "/eslint.config.mts")) == 1
			or vim.fn.filereadable(vim.fs.joinpath(params.rootPath, "/eslint.config.cts")) == 1
		then
			config.settings = config.settings or {}
			config.settings.experimental = config.settings.experimental or {}
			---@diagnostic disable-next-line: inject-field
			config.settings.experimental.useFlatConfig = true
		end

		-- Support Yarn2 (PnP) projects
		local pnp_cjs = vim.fs.joinpath(params.rootPath, "/.pnp.cjs")
		local pnp_js = vim.fs.joinpath(params.rootPath, "/.pnp.js")
		if vim.uv.fs_stat(pnp_cjs) or vim.uv.fs_stat(pnp_js) then
			vim.validate("cmd", config.cmd, "table", false, "Eslint cannot be an in process server")
			local cmd = config.cmd --[[@as string[] ]]
			config.cmd = vim.list_extend({ "yarn", "exec" }, cmd)
		end
	end,
	on_attach = function(client, bufnr)
		vim.api.nvim_buf_create_user_command(bufnr, "EslintFixAll", function()
			client:request_sync("workspace/executeCommand", {
				command = "eslint.applyAllFixes",
				arguments = {
					{
						uri = vim.uri_from_bufnr(bufnr),
						version = vim.lsp.util.buf_versions[bufnr],
					},
				},
			}, nil, bufnr)
		end, { desc = "Fix all eslint problems for this buffer" })
	end,
	handlers = {
		["eslint/openDoc"] = function(_, result)
			if result then
				vim.ui.open(result.url)
			end
			return {}
		end,
		["eslint/confirmESLintExecution"] = function(_, result)
			if not result then
				return
			end
			return 4 -- approved
		end,
		["eslint/probeFailed"] = function()
			vim.notify("[lspconfig] ESLint probe failed.", vim.log.levels.WARN)
			return {}
		end,
		["eslint/noLibrary"] = function()
			vim.notify("[lspconfig] Unable to find ESLint library.", vim.log.levels.WARN)
			return {}
		end,
	},
}
