---Specification regarding language-servers, formatters and linters
---@class (exact) Tools
---@field mason string[] Tools (including LSPs) to install via mason. LSPs listed here are automatically configured
---@field system_lsps string[] LSPs that need to be enabled in addition to those installed with mason
---@field lsp_default_config vim.lsp.Config The default configuration for all LSPs
local Tools = {
	mason = {
		-- LSPs
		"eslint",
		"tinymist",
		"vtsls",
		"jsonls",
		"yamlls",
		"lua_ls",
		"zls",
		"basedpyright",
		"ruff",
		"bashls",
		-- formatters
		"stylua",
		"shfmt",
		-- linters
		"shellcheck",
	},

	system_lsps = {
		"clangd",
		"rust_analyzer",
		"glsl_analyzer",
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
}

return Tools
