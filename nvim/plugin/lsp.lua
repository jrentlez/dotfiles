vim.api.nvim_create_autocmd("LspAttach", {
	group = vim.api.nvim_create_augroup("default-lsp-attach", { clear = true }),
	callback = function(event)
		-- {{{ Set up LSP features not enabled by default
		local client = assert(vim.lsp.get_client_by_id(event.data.client_id))
		local lsp_augroup = vim.api.nvim_create_augroup("custom-lsp-autocmds", { clear = false })
		local methods = vim.lsp.protocol.Methods ---@type vim.lsp.protocol.Methods

		if client:supports_method(methods.textDocument_definition, event.buf) then
			vim.keymap.set("n", "gd", vim.lsp.buf.definition, { buffer = event.buf })
		end
		if client:supports_method(methods.textDocument_declaration, event.buf) then
			vim.keymap.set("n", "gD", vim.lsp.buf.declaration, { buffer = event.buf })
		end

		if
			client:supports_method(methods.textDocument_foldingRange, event.buf)
			and not vim.api.nvim_get_option_info2("foldmethod", {}).was_set
		then
			vim.o.foldmethod = "expr"
			vim.o.foldexpr = "v:lua.vim.lsp.foldexpr()"
			vim.o.foldtext = "v:lua.vim.lsp.foldtext()"
			vim.o.foldlevel = 99
			vim.o.foldlevelstart = 99
		end

		if client:supports_method(methods.textDocument_completion, event.buf) then
			vim.lsp.completion.enable(true, client.id, event.buf, { autotrigger = true })
		end

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
		end

		if client:supports_method(methods.textDocument_inlayHint, event.buf) then
			vim.keymap.set("n", "zI", function()
				vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled())
			end, { buffer = event.buf })
		end

		if client:supports_method(methods.textDocument_linkedEditingRange, event.buf) then
			vim.lsp.linked_editing_range.enable(true, { client_id = client.id })
		end

		if client:supports_method(methods.textDocument_codeLens, event.buf) then
			vim.api.nvim_create_autocmd({ "BufEnter", "CursorHold", "InsertLeave", "BufWritePost" }, {
				group = lsp_augroup,
				buffer = event.buf,
				callback = vim.lsp.codelens.refresh,
			})
			vim.keymap.set("n", "grl", vim.lsp.codelens.run, { buffer = event.buf })
		end

		vim.b[event.buf].format_on_save_autocmd_id = vim.b[event.buf].format_on_save_autocmd_id
			or vim.api.nvim_create_autocmd("BufWritePre", {
				buffer = event.buf,
				group = lsp_augroup,
				callback = function(args)
					local formatlsp = vim.b[args.buf].formatlsp or vim.g.formatlsp
					if formatlsp == false then
						return
					elseif formatlsp == true then
						formatlsp = nil
					end
					vim.lsp.buf.format({ bufnr = args.buf, name = formatlsp })
				end,
			}) -- }}}
	end,
})

---HACK: according to `emmylua_ls` the `cfg` parameter is missing a `cmd` field, which is not actually required
---@diagnostic disable-next-line: param-type-not-match
vim.lsp.config("*", {
	handlers = {
		[vim.lsp.protocol.Methods.client_registerCapability] = function(err, params, ctx)
			-- {{{ Notify when a language server registers a capability
			local client = assert(vim.lsp.get_client_by_id(ctx.client_id))
			for _, registration in ipairs(params.registrations) do
				vim.notify("[" .. client.name .. "] Register capability: " .. registration.method, vim.log.levels.INFO)
			end
			return vim.lsp.handlers[vim.lsp.protocol.Methods.client_registerCapability](err, params, ctx) -- }}}
		end,
	},
})

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

-- vim: foldmethod=marker
