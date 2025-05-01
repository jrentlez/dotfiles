---Specification regarding language-servers, formatters and linters
---@class (exact) ToolSpec
---@field lsps string[] Language server to ensure installed and to configure
---@field lsp_inhibit fun(server_name: string) Do not start this (enabled) LSP
---@field lsp_default_config vim.lsp.Config The default configuration for all LSPs. Should be passed to `vim.lsp.config()`
---@field other_tools string[] List of non-lsp tools that mason should install
---@field all_specified_tools fun(self): string[] List all tools named in the spec
---@field tool_installation_status fun(tool_name: string): nil | "install-via-mason" | "installed-mason" | "installed-system" | "installed-in-process" Check if a tool is installed, and if so through what method or if it needs to be installed with mason
---@field specified_and_installed_lsps fun(self): string[] List all LSPs that are either installed through mason or specified in the `lsps` field
local ToolSpec = {
	lsps = {
		"eslint",
		"clangd",
		"lua_ls",
		"tinymist",
		"vtsls",
		"jsonls",
		"yamlls",
		"zls",
		"basedpyright",
		"ruff",
		"bashls",
		"rust_analyzer",
		"nushell",
		"jayvee_ls",
		"stylua3p_ls",
	},
	lsp_default_config = {
		handlers = {
			---@param params lsp.RegistrationParams
			---@param ctx lsp.HandlerContext
			[vim.lsp.protocol.Methods.client_registerCapability] = function(err, params, ctx)
				---@type vim.lsp.Client
				local client = assert(vim.lsp.get_client_by_id(ctx.client_id))
				for _, registration in ipairs(params.registrations) do
					vim.notify(
						string.format("[%s] Register capability: %s", client.name, registration.method),
						vim.log.levels.INFO
					)
				end
				return vim.lsp.handlers[vim.lsp.protocol.Methods.client_registerCapability](err, params, ctx)
			end,
		},
	},

	other_tools = {
		-- formatters
		"stylua",
		"latexindent",
		"shfmt",
		-- linters
		"shellcheck",
	},
}

function ToolSpec:all_specified_tools()
	local tools = vim.deepcopy(self.lsps)
	return vim.list_extend(tools, self.other_tools)
end

function ToolSpec:specified_and_installed_lsps()
	local lsps = {}
	vim.iter(self.lsps):each(function(server_name)
		lsps[server_name] = true
	end)
	vim.iter(require("mason-lspconfig").get_installed_servers()):each(function(server_name)
		lsps[server_name] = true
	end)
	return vim.tbl_keys(lsps)
end

function ToolSpec.lsp_inhibit(server_name)
	vim.lsp.config(server_name, {
		workspace_required = true,
		root_dir = function(_, cb)
			cb(nil)
		end,
		root_markers = {},
	} --[[@as vim.lsp.Config]])
end

function ToolSpec.tool_installation_status(tool_name)
	local mason_name = require("mason-lspconfig").get_mappings().lspconfig_to_mason[tool_name] or tool_name

	if require("mason-registry").is_installed(mason_name) then
		return "installed-mason"
	elseif vim.fn.executable(tool_name) == 1 then
		return "installed-system"
	else
		local lspconfig = vim.lsp.config[tool_name] --[[@as vim.lsp.Config|nil]]
		if lspconfig then
			if type(lspconfig.cmd) == "function" then
				return "installed-in-process"
			elseif vim.fn.executable(lspconfig.cmd[1]) == 1 then
				return "installed-system"
			end
		end

		return require("mason-registry").has_package(mason_name) and "install-via-mason" or nil
	end
end

return ToolSpec
