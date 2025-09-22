local lsp_augroup = vim.api.nvim_create_augroup("lsp-augroup", { clear = true })

vim.api.nvim_create_autocmd("LspAttach", {
	group = lsp_augroup,
	callback = function(event)
		local client = assert(vim.lsp.get_client_by_id(event.data.client_id))
		local methods = vim.lsp.protocol.Methods

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
				callback = function() vim.lsp.buf.document_highlight() end,
			})
			vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
				buffer = event.buf,
				group = lsp_augroup,
				callback = function() vim.lsp.buf.clear_references() end,
			})
		end
	end,
})

vim.api.nvim_create_autocmd("VimLeave", {
	group = lsp_augroup,
	callback = function() vim.api.nvim_ui_send("\027]9;4;0\027\\") end,
})
vim.api.nvim_create_autocmd("LspProgress", {
	group = lsp_augroup,
	callback = function(event)
		local token = event.data.params.token ---@type string | integer
		local message = event.data.params.value.message or "done" ---@type string
		local title = event.data.params.value.title ---@type string
		local running = event.data.params.value.kind ~= "end" ---@type boolean
		local percent = running and (event.data.params.value.percentage or 0) or nil
		vim.api.nvim_echo({ { message } }, true, {
			id = token,
			title = title,
			kind = "progress",
			status = running and "running" or "success",
			percent = percent,
		})
		vim.api.nvim_ui_send("\027]9;4;" .. (running and ("1;" .. percent) or 0) .. "\027\\")
	end,
})

vim.api.nvim_create_autocmd("BufWritePre", {
	group = lsp_augroup,
	callback = function(event)
		local formatlsp = vim.b[event.buf].formatlsp ---@type (string | boolean)?
		if formatlsp == nil then
			formatlsp = vim.g.formatlsp ---@type (string | boolean)?
		end

		if formatlsp == true then
			formatlsp = nil
		elseif formatlsp == false then
			return
		end
		---@cast formatlsp string?

		local formatting_clients = vim.lsp.get_clients({
			bufnr = event.buf,
			name = formatlsp,
			method = vim.lsp.protocol.Methods.textDocument_formatting,
		})
		if not vim.tbl_isempty(formatting_clients) then
			vim.lsp.buf.format({ bufnr = event.buf, name = formatlsp })
		end
	end,
})

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
	vim.pack.add({ "https://github.com/neovim/nvim-lspconfig" })

	vim.lsp.on_type_formatting.enable()
	vim.lsp.linked_editing_range.enable()
	vim.keymap.set("n", "grh", function() vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled()) end)
	vim.lsp.enable({
		"basedpyright",
		"bashls",
		"clangd",
		"eslint",
		"glsl_analyzer",
		"jsonls",
		"lua_ls",
		"ruff",
		"rust_analyzer",
		"stylua",
		"tinymist",
		"vtsls",
		"yamlls",
		"html",
	})
end)
