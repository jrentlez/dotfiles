---@module "mini.deps"

local add, now = MiniDeps.add, MiniDeps.now

now(function()
	add({
		source = "williamboman/mason-lspconfig.nvim",
		depends = {
			"neovim/nvim-lspconfig",
			"williamboman/mason.nvim",
		},
	})
	add("jvalue/jayvee.nvim")

	vim.api.nvim_create_autocmd("LspAttach", {
		group = vim.api.nvim_create_augroup("default-lsp-attach", { clear = true }),
		callback = function(event)
			local client = vim.lsp.get_client_by_id(event.data.client_id)
			if not client then
				return
			end

			-- Lsp folds
			if client:supports_method(vim.lsp.protocol.Methods.textDocument_foldingRange, event.buf) then
				vim.o.foldmethod = "expr"
				vim.o.foldexpr = "v:lua.vim.lsp.foldexpr()"
				vim.o.foldtext = "v:lua.vim.lsp.foldtext()"
				vim.o.foldlevel = 99
				vim.o.foldlevelstart = 99
			end

			-- Lsp completion
			if client:supports_method(vim.lsp.protocol.textDocument_completion, event.buf) then
				vim.bo[event.buf].omnifunc = "v:lua.MiniCompletion.completefunc_lsp"
			end

			-- Keymaps
			local pnmap = function(lhs, scope, desc)
				vim.keymap.set("n", lhs, function()
					require("mini.extra").pickers.lsp({ scope = scope }, {})
				end, { desc = desc, buffer = event.buf })
			end
			if client:supports_method(vim.lsp.protocol.Methods.textDocument_definition, event.buf) then
				pnmap("gd", "definition", "vim.lsp.buf.definition()")
			end
			if client:supports_method(vim.lsp.protocol.Methods.textDocument_declaration, event.buf) then
				pnmap("gD", "declaration", "vim.lsp.buf.declaration()")
			end
			if client:supports_method(vim.lsp.protocol.Methods.textDocument_typeDefinition, event.buf) then
				pnmap("grt", "type_definition", "vim.lsp.buf.type_definition()")
			end
			if client:supports_method(vim.lsp.protocol.Methods.textDocument_documentSymbol, event.buf) then
				pnmap("grs", "document_symbol", "vim.lsp.buf.document_symbol()")
			end
			if client:supports_method(vim.lsp.protocol.Methods.textDocument_implementation, event.buf) then
				pnmap("gri", "implementation", "vim.lsp.buf.implementation()")
			end
			if client:supports_method(vim.lsp.protocol.Methods.textDocument_references, event.buf) then
				pnmap("grr", "references", "vim.lsp.buf.references()")
			end
			if client:supports_method(vim.lsp.protocol.Methods.workspace_symbol, event.buf) then
				pnmap("grw", "workspace_symbol", "vim.lsp.buf.workspace_sybmol()")
			end
			if client:supports_method(vim.lsp.protocol.Methods.textDocument_signatureHelp, event.buf) then
				vim.keymap.set(
					"i",
					"<C-k>",
					vim.lsp.buf.signature_help,
					{ desc = "vim.lsp.buf.signature_help()", buffer = event.buf }
				)
			end

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

			-- Enable document color
			if client:supports_method(vim.lsp.protocol.Methods.document_color) then
				vim.lsp.document_color.enable(true, event.buf)
			end

			-- Enable codelens
			if client:supports_method(vim.lsp.protocol.Methods.textDocument_codeLens, event.buf) then
				vim.api.nvim_create_autocmd({ "BufEnter", "CursorHold", "InsertLeave", "BufWritePost" }, {
					group = lsp_augroup,
					buffer = event.buf,
					callback = vim.lsp.codelens.refresh,
					desc = "Refresh codelens",
				})
				vim.keymap.set(
					"n",
					"grl",
					vim.lsp.codelens.run,
					{ desc = "vim.lsp.codelens.run()", buffer = event.buf }
				)
			end

			-- Enable format on save
			vim.b[event.buf].lsp_format_on_save_autocmd = vim.b[event.buf].lsp_format_on_save_autocmd
				or vim.api.nvim_create_autocmd("BufWritePre", {
					desc = "Attempt to format with LSP(s)",
					buffer = event.buf,
					group = lsp_augroup,
					callback = function(args)
						local server_name = vim.b[args.buf].lspfmt
						if server_name and server_name == "" then
							return
						end
						vim.lsp.buf.format({ bufnr = args.buf, name = server_name })
					end,
				})
		end,
		desc = "LSP configuration",
	})

	vim.api.nvim_create_autocmd("LspDetach", {
		group = vim.api.nvim_create_augroup("default-lsp-detach", { clear = true }),
		callback = function(detach)
			local lsp_augroup = vim.api.nvim_create_augroup("custom-lsp-autocmds", { clear = false })
			vim.lsp.buf.clear_references()
			vim.api.nvim_clear_autocmds({
				group = lsp_augroup,
				buffer = detach.buf,
			})
			vim.b[detach.buf].lsp_format_on_save_autocmd = nil
			vim.lsp.inlay_hint.enable(false, { bufnr = detach.buf })

			-- Remove keymaps
			local keymaps = vim.api.nvim_buf_get_keymap(detach.buf, "n")
			local delmap = function(lhs)
				for _, keymap in ipairs(keymaps) do
					if keymap.lhs == lhs then
						vim.keymap.del("n", lhs, { buffer = detach.buf })
						return
					end
				end
			end

			delmap("gD") -- WARN: Deletes preexisting keymap
			delmap("gd") -- WARN: Deletes preexisting keymap
			delmap("grt")
			delmap("grs")
			delmap("gri")
			delmap("grr")
			delmap("grw")
			delmap("grl")
		end,
		desc = "Cleanup lsp-configuration",
	})

	---@diagnostic disable-next-line: missing-fields
	require("mason").setup({
		PATH = "append",
	})

	vim.lsp.config("*", require("spec").lsp_default_config)

	vim.lsp.enable(require("spec"):specified_and_installed_lsps())
end)
