---@param event vim.api.keyset.create_autocmd.callback_args
---@return boolean? delete Whether to delete the autocmd after exectuion
local function on_lsp_attach(event)
	local client = assert(vim.lsp.get_client_by_id(event.data.client_id))

	-- Lsp folds
	if client:supports_method(vim.lsp.protocol.Methods.textDocument_foldingRange, event.buf) then
		---@param option string
		---@param value any
		local function set_if_unset(option, value)
			if not vim.api.nvim_get_option_info2(option, {}).was_set then
				vim.o[option] = value
			end
		end
		set_if_unset("foldmethod", "expr")
		set_if_unset("foldexpr", "v:lua.vim.lsp.foldexpr()")
		set_if_unset("foldtext", "v:lua.vim.lsp.foldtext()")
		set_if_unset("foldlevel", 99)
		set_if_unset("foldlevelstart", 99)
	end

	-- Lsp completion
	if client:supports_method(vim.lsp.protocol.Methods.textDocument_completion, event.buf) then
		vim.lsp.completion.enable(true, client.id, event.buf)
	end

	-- Keymaps (see :help lsp-defaults for already existing keymaps)

	---@param method vim.lsp.protocol.Method.ClientToServer
	---@param lhs string
	---@param rhs fun()
	---@param desc string
	local function lsp_map(method, lhs, rhs, desc)
		if client:supports_method(method, event.buf) then
			vim.keymap.set("n", lhs, rhs, { desc = desc, buffer = event.buf })
		end
	end
	lsp_map(vim.lsp.protocol.Methods.textDocument_definition, "gd", vim.lsp.buf.definition, "vim.lsp.buf.definition()")
	lsp_map(
		vim.lsp.protocol.Methods.textDocument_declaration,
		"gD",
		vim.lsp.buf.declaration,
		"vim.lsp.buf.definition()"
	)
	lsp_map(vim.lsp.protocol.Methods.textDocument_workspace_symbol, "grw", function()
		vim.lsp.buf.workspace_symbol()
	end, "vim.lsp.buf.workspace_symbol()")

	local lsp_augroup = vim.api.nvim_create_augroup("custom-lsp-autocmds", { clear = false })

	-- The following two autocommands are used to highlight references of the
	-- word under your cursor when your cursor rests there for a little while.
	--    See `:help CursorHold` for information about when this is executed
	if client:supports_method(vim.lsp.protocol.Methods.textDocument_documentHighlight, event.buf) then
		vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
			buffer = event.buf,
			group = lsp_augroup,
			callback = vim.lsp.buf.document_highlight,
		})
		vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
			buffer = event.buf,
			group = lsp_augroup,
			callback = vim.lsp.buf.clear_references,
		})
	end

	-- Enable inlay hints
	if client:supports_method(vim.lsp.protocol.Methods.textDocument_inlayHint, event.buf) then
		vim.lsp.inlay_hint.enable(true, { bufnr = event.buf })
	end

	-- Enable linked editing ranges
	if client:supports_method(vim.lsp.protocol.Methods.textDocument_linkedEditingRange, event.buf) then
		vim.lsp.linked_editing_range.enable(true, { client_id = client.id })
	end

	-- Enable codelens
	if client:supports_method(vim.lsp.protocol.Methods.textDocument_codeLens, event.buf) then
		vim.api.nvim_create_autocmd({ "BufEnter", "CursorHold", "InsertLeave", "BufWritePost" }, {
			group = lsp_augroup,
			buffer = event.buf,
			callback = vim.lsp.codelens.refresh,
			desc = "Refresh codelens",
		})
		vim.keymap.set("n", "grl", vim.lsp.codelens.run, { desc = "vim.lsp.codelens.run()", buffer = event.buf })
	end

	-- Enable format on save
	vim.b[event.buf].lsp_format_on_save_autocmd = vim.b[event.buf].lsp_format_on_save_autocmd
		or vim.api.nvim_create_autocmd("BufWritePre", {
			desc = "Attempt to format with language server(s)",
			buffer = event.buf,
			group = lsp_augroup,
			callback = function(args)
				local server_name = vim.b[args.buf].formatlsp
				if server_name == "" then
					return
				end
				vim.lsp.buf.format({ bufnr = args.buf, name = server_name })
			end,
		})

	-- HACK: Disable lsp comment highlighting so the treesitter comment parser can highlight TODO, FIXME, etc.
	if client:supports_method(vim.lsp.protocol.Methods.textDocument_semanticTokens_full, event.buf) then
		vim.api.nvim_set_hl(0, "@lsp.type.comment", {})

		vim.api.nvim_create_autocmd("ColorScheme", {
			desc = "Disable lsp comment highlighting so the treesitter comment parser can highlight TODO, FIXME, etc.",
			group = vim.api.nvim_create_augroup("clear-lsp-comment-highlight", { clear = true }),
			callback = function()
				vim.api.nvim_set_hl(0, "@lsp.type.comment", {})
			end,
		})
	end
end

---@param params lsp.RegistrationParams
---@param ctx lsp.HandlerContext
local function notify_on_registered_capability(err, params, ctx)
	local client = assert(vim.lsp.get_client_by_id(ctx.client_id))

	for _, registration in ipairs(params.registrations) do
		vim.notify(string.format("[%s] Register capability: %s", client.name, registration.method), vim.log.levels.INFO)
	end

	return vim.lsp.handlers[vim.lsp.protocol.Methods.client_registerCapability](err, params, ctx)
end

vim.schedule(function()
	vim.pack.add({
		"https://github.com/neovim/nvim-lspconfig.git",
	})

	vim.api.nvim_create_autocmd("LspAttach", {
		group = vim.api.nvim_create_augroup("default-lsp-attach", { clear = true }),
		callback = on_lsp_attach,
		desc = "Language server setup",
	})

	---HACK: according to `emmylua_ls` the `cfg` parameter is missing a `cmd` field, which is not actually required
	---@diagnostic disable-next-line: param-type-not-match
	vim.lsp.config("*", {
		handlers = {
			[vim.lsp.protocol.Methods.client_registerCapability] = notify_on_registered_capability,
		},
	})

	vim.lsp.enable({
		"basedpyright",
		"bashls",
		"clangd",
		"eslint",
		"glsl_analyzer",
		"jayvee_ls",
		"jsonls",
		"emmylua_ls",
		"ruff",
		"rust_analyzer",
		"stylua3p_ls",
		"tinymist",
		"vtsls",
		"yamlls",
		"html",
	})
end)
