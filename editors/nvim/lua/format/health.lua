local M = {}

---@param bufnr integer
local function check_buffer(bufnr)
	if not vim.bo[bufnr].buflisted or vim.bo[bufnr].buftype ~= "" then
		return
	end
	local buf_name = vim.api.nvim_buf_get_name(bufnr)
	buf_name = buf_name == "" and "[No Name]" or (vim.fs.relpath(assert(vim.uv.cwd()), buf_name) or buf_name)

	vim.health.start("Formatting language server(s) for " .. buf_name)

	local fmt_autocmd_id = vim.b[bufnr].lsp_format_on_save_autocmd --[[@as integer?]]
	if not fmt_autocmd_id then
		if vim.tbl_isempty(vim.lsp.get_clients({ bufnr = bufnr })) then
			vim.health.info("No language servers attached")
		else
			vim.health.error(
				"No format-on-save autocommand",
				"The autocommand should be created on every `LspAttach` event"
			)
		end
		return
	end
	local fmt_autocmds = vim.api.nvim_get_autocmds({ id = fmt_autocmd_id, buffer = bufnr })
	assert(#fmt_autocmds == 1)

	local server_name = vim.b[bufnr].formatlsp --[[@as string?]]
	if server_name and server_name == "" then
		vim.health.info('Formatting on save disabled (`vim.b.formatlsp = ""`)')
		return
	elseif server_name then
		vim.health.info(('`vim.b.formatlsp = "%s"`'):format(server_name))
	else
		vim.health.info("No specific formatting language server set (`vim.b.formatlsp = nil`)")
	end

	local formatting_lsps = vim.lsp.get_clients({
		name = server_name,
		bufnr = bufnr,
		method = vim.lsp.protocol.Methods.textDocument_formatting,
	})
	if #formatting_lsps <= 0 then
		if server_name then
			vim.health.error(("`%s` cannot format the buffer"):format(server_name), {
				("`%s` may not be attached to the buffer"):format(server_name),
				('`%s` may not support `"%s"`'):format(server_name, vim.lsp.protocol.Methods.textDocument_formatting),
			})
		else
			vim.health.warn("No language server with formatting capabilities attached to buffer")
		end
		return
	end

	for _, client in ipairs(formatting_lsps) do
		assert(client:supports_method(vim.lsp.protocol.Methods.textDocument_formatting, bufnr))
		vim.health.ok(("Formatting with `%s` (id: %d)"):format(client.name, client.id))
	end
end

function M.check()
	vim.iter(vim.api.nvim_list_bufs()):each(check_buffer)
end
return M
