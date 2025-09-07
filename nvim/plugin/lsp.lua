vim.api.nvim_create_autocmd("LspAttach", {
	group = vim.api.nvim_create_augroup("default-lsp-attach", { clear = true }),
	callback = function(event)
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

		if client:supports_method(methods.textDocument_codeLens, event.buf) then
			vim.api.nvim_create_autocmd({ "BufEnter", "CursorHold", "InsertLeave", "BufWritePost" }, {
				group = lsp_augroup,
				buffer = event.buf,
				callback = vim.lsp.codelens.refresh,
			})
		end
	end,
})

---HACK: according to `emmylua_ls` the `cfg` parameter is missing a `cmd` field, which is not actually required
---@diagnostic disable-next-line: param-type-not-match
vim.lsp.config("*", {
	handlers = {
		[vim.lsp.protocol.Methods.client_registerCapability] = function(err, params, ctx)
			local client = assert(vim.lsp.get_client_by_id(ctx.client_id))
			for _, registration in ipairs(params.registrations) do
				vim.notify(
					"[" .. client.name .. "] Register capability: " .. registration.method,
					vim.log.levels.INFO
				)
			end
			return vim.lsp.handlers[vim.lsp.protocol.Methods.client_registerCapability](err, params, ctx)
		end,
	},
})

vim.schedule(function()
	vim.pack.add({
		"https://github.com/neovim/nvim-lspconfig",
		"https://github.com/TungstnBallon/formatlsp.nvim",
	})
	vim.lsp.on_type_formatting.enable()
	vim.lsp.linked_editing_range.enable()
	vim.keymap.set("n", "grh", function()
		vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled())
	end)
	vim.keymap.set("n", "grl", vim.lsp.codelens.run)
	vim.lsp.enable({
		"basedpyright",
		"bashls",
		"clangd",
		"eslint",
		"glsl_analyzer",
		"jsonls",
		"emmylua_ls",
		"ruff",
		"rust_analyzer",
		"stylua",
		"tinymist",
		"vtsls",
		"yamlls",
		"html",
	})
end)
