local M = {}

---@param bufnr integer
local function check_buffer(bufnr)
	if not vim.bo[bufnr].buflisted or vim.bo[bufnr].buftype ~= "" then
		return
	end
	local buf_name = vim.api.nvim_buf_get_name(bufnr)
	buf_name = buf_name == "" and "[No Name]" or (vim.fs.relpath(assert(vim.uv.cwd()), buf_name) or buf_name)

	local fmt_autocmd_id = vim.b[bufnr].lsp_format_on_save_autocmd --[[@as integer?]]
	if not fmt_autocmd_id then
		if vim.bo[bufnr].filetype == "" then
			vim.health.info(("%s: default |filetype|"):format(buf_name))
		else
			vim.health.warn(
				("No format-on-save autocommand for '%s'"):format(buf_name),
				"The autocommand is only created once a LSP is attached to the buffer"
			)
		end
		return
	end
	local fmt_autocmds = vim.api.nvim_get_autocmds({ id = fmt_autocmd_id, buffer = bufnr })
	assert(#fmt_autocmds == 1)

	vim.health.start(("LSP formatter(s) for '%s'"):format(buf_name))

	local server_name = vim.b[bufnr].lspfmt --[[@as string?]]
	if server_name and server_name == "" then
		vim.health.info("Formatting on save disabled (vim.b.lspfmt = '')")
		return
	elseif server_name then
		vim.health.info(("vim.b.lspfmt = '%s'"):format(server_name))
	else
		vim.health.info("No specific LSP formatter set (vim.b.lspfmt = nil)")
	end

	local formatting_lsps = vim.lsp.get_clients({
		name = server_name,
		bufnr = bufnr,
		method = vim.lsp.protocol.Methods.textDocument_formatting,
	})
	if #formatting_lsps <= 0 then
		if server_name then
			vim.health.error(
				("'%s' cannot format the buffer, either because it is not attached, or because it does not support '%s'"):format(
					server_name,
					vim.lsp.protocol.Methods.textDocument_formatting
				),
				{
					("'%s' may not be attached to the buffer"):format(server_name),
					("'%s' may not support '%s'"):format(server_name, vim.lsp.protocol.Methods.textDocument_formatting),
				}
			)
		else
			vim.health.warn("No LSP with formatting capabilities attached to buffer")
		end
		return
	end

	for _, client in ipairs(formatting_lsps) do
		assert(client:supports_method(vim.lsp.protocol.Methods.textDocument_formatting, bufnr))
		vim.health.ok(("Formatting with LSP '%s' (id: %d)"):format(client.name, client.id))
	end
end

function M.check()
	vim.iter(vim.api.nvim_list_bufs()):each(check_buffer)
end
return M
