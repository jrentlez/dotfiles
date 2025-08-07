local M = {}

-- {{{ check_buffer and helpers
-- {{{ Helpers

---@param bufnr integer
---@return string buf_name
local function get_buf_name(bufnr)
	local buf_name = vim.api.nvim_buf_get_name(bufnr)
	return buf_name == "" and "[No Name]" or (vim.fs.relpath(assert(vim.uv.cwd()), buf_name) or buf_name)
end

---@param bufnr integer
---@return boolean ok
local function check_buffer_has_one_format_autocmd(bufnr)
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
		return false
	end
	local fmt_autocmds = vim.api.nvim_get_autocmds({ id = fmt_autocmd_id, buffer = bufnr })
	assert(#fmt_autocmds == 1)
	return true
end

---@param bufnr integer
---@return boolean ok
local function check_formatlsp_valid(bufnr)
	local formatlsp = vim.b[bufnr].formatlsp
	if formatlsp == "" then
		vim.health.info('Formatting on save disabled (`vim.b.formatlsp = ""`)')
		return false
	elseif formatlsp == nil then
		vim.health.info("No specific formatting language server set (`vim.b.formatlsp = nil`)")
		return true
	elseif type(formatlsp) == "string" then
		vim.health.info(('`vim.b.formatlsp = "%s"`'):format(formatlsp))
		return true
	else
		vim.health.error("`vim.b.formatlsp` is expected to be either a string or nil")
		return false
	end
end

---@param bufnr integer
---@return boolean ok
local function check_formatting_clients_attached(bufnr)
	local formatlsp = vim.b[bufnr].formatlsp --[[@as string?]]
	local formatting_clients = vim.lsp.get_clients({
		name = formatlsp,
		bufnr = bufnr,
		method = vim.lsp.protocol.Methods.textDocument_formatting,
	})
	if not vim.tbl_isempty(formatting_clients) then
		for _, client in ipairs(formatting_clients) do
			vim.health.ok(("Formatting with `%s` (id: %d)"):format(client.name, client.id))
		end
	elseif formatlsp then
		vim.health.error(("`%s` cannot format the buffer"):format(formatlsp), {
			("`%s` may not be attached to the buffer"):format(formatlsp),
			('`%s` may not support `"%s"`'):format(formatlsp, vim.lsp.protocol.Methods.textDocument_formatting),
		})
	else
		vim.health.warn("No language server with formatting capabilities attached to buffer")
	end
end -- }}}

---@param bufnr integer
local function check_buffer(bufnr)
	if not vim.bo[bufnr].buflisted or vim.bo[bufnr].buftype ~= "" then
		return
	end

	vim.health.start("Formatting language server(s) for " .. get_buf_name(bufnr))
	local _ok = check_buffer_has_one_format_autocmd(bufnr)
		and check_formatlsp_valid(bufnr)
		and check_formatting_clients_attached(bufnr)
end -- }}}

function M.check()
	vim.iter(vim.api.nvim_list_bufs()):each(check_buffer)
end
return M
