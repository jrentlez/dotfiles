-- {{{ Set up LSP features not enabled by default

vim.api.nvim_create_autocmd("LspAttach", {
	group = vim.api.nvim_create_augroup("default-lsp-attach", { clear = true }),
	callback = function(event)
		local client = assert(vim.lsp.get_client_by_id(event.data.client_id))
		local lsp_augroup = vim.api.nvim_create_augroup("custom-lsp-autocmds", { clear = false })
		local methods = vim.lsp.protocol.Methods ---@type vim.lsp.protocol.Methods

		-- {{{ Go to definition/declaration
		if client:supports_method(methods.textDocument_definition, event.buf) then
			vim.keymap.set("n", "gd", vim.lsp.buf.definition, { desc = "vim.lsp.buf.definition()", buffer = event.buf })
		end
		if client:supports_method(methods.textDocument_declaration, event.buf) then
			vim.keymap.set(
				"n",
				"gD",
				vim.lsp.buf.declaration,
				{ desc = "vim.lsp.buf.declaration()", buffer = event.buf }
			)
		end -- }}}
		-- {{{ Folds
		if client:supports_method(methods.textDocument_foldingRange, event.buf) then
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
		end -- }}}
		-- {{{ Completion
		if client:supports_method(methods.textDocument_completion, event.buf) then
			vim.lsp.completion.enable(true, client.id, event.buf, { autotrigger = true })
		end -- }}}
		-- {{{ Document highlight
		if client:supports_method(methods.textDocument_documentHighlight, event.buf) then
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
		end -- }}}
		-- {{{ Inlay hints
		if client:supports_method(methods.textDocument_inlayHint, event.buf) then
			vim.keymap.set("n", "zI", function()
				vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled())
			end, { desc = "Toggle inlay hints", buffer = event.buf })
		end -- }}}
		-- {{{ Linked editing ranges
		if client:supports_method(methods.textDocument_linkedEditingRange, event.buf) then
			vim.lsp.linked_editing_range.enable(true, { client_id = client.id })
		end -- }}}
		-- {{{ Codelens
		if client:supports_method(methods.textDocument_codeLens, event.buf) then
			vim.api.nvim_create_autocmd({ "BufEnter", "CursorHold", "InsertLeave", "BufWritePost" }, {
				group = lsp_augroup,
				buffer = event.buf,
				callback = vim.lsp.codelens.refresh,
				desc = "Refresh codelens",
			})
			vim.keymap.set("n", "grl", vim.lsp.codelens.run, { desc = "vim.lsp.codelens.run()", buffer = event.buf })
		end -- }}}
		-- {{{ Format on save
		vim.b[event.buf].format_on_save_autocmd_id = vim.b[event.buf].format_on_save_autocmd_id
			or vim.api.nvim_create_autocmd("BufWritePre", {
				desc = "Attempt to format with language server(s)",
				buffer = event.buf,
				group = lsp_augroup,
				callback = function(args)
					local formatlsp = vim.b[args.buf].formatlsp or vim.g.formatlsp
					if formatlsp ~= "" then
						vim.lsp.buf.format({ bufnr = args.buf, name = formatlsp })
					end
				end,
			}) -- }}}
	end,
	desc = "Language server setup",
}) -- }}}

-- {{{ Notify when a language server registers a capability
---HACK: according to `emmylua_ls` the `cfg` parameter is missing a `cmd` field, which is not actually required
---@diagnostic disable-next-line: param-type-not-match
vim.lsp.config("*", {
	handlers = {
		[vim.lsp.protocol.Methods.client_registerCapability] = function(err, params, ctx)
			local client = assert(vim.lsp.get_client_by_id(ctx.client_id))
			for _, registration in ipairs(params.registrations) do
				vim.notify("[" .. client.name .. "] Register capability: " .. registration.method, vim.log.levels.INFO)
			end
			return vim.lsp.handlers[vim.lsp.protocol.Methods.client_registerCapability](err, params, ctx)
		end,
	},
})
-- }}}

vim.schedule(function()
	vim.pack.add({
		"https://github.com/neovim/nvim-lspconfig",
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
