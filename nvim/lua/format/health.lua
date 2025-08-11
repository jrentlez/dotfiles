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
---@return boolean continue
---@return boolean add_to_noformat_list
local function check_buffer_has_one_format_autocmd(bufnr)
	local format_autocmds = vim.api.nvim_get_autocmds({
		buffer = bufnr,
		event = "BufWritePre",
		group = vim.api.nvim_create_augroup("format-on-save", { clear = false }),
	})
	if #format_autocmds == 0 and vim.tbl_isempty(vim.lsp.get_clients({ bufnr = bufnr })) then
		return false, true
	end

	vim.health.start(get_buf_name(bufnr))
	if #format_autocmds == 0 then
		vim.health.error("No format-on-save autocmd", "The autocmd should be created on every `LspAttach` event")
		return false, false
	elseif #format_autocmds > 1 then
		vim.health.error(
			"This buffer has " .. #format_autocmds .. " format-on-save autocmds",
			"The autocmd should be created once per buffer"
		)
	end
	return true, false
end

---@param bufnr? integer
---@return boolean ok
local function check_formatlsp_valid(bufnr)
	local formatlsp
	if bufnr then
		formatlsp = vim.b[bufnr].formatlsp
	else
		formatlsp = vim.g.formatlsp
	end
	local scope = bufnr and "b" or "g"
	if formatlsp == nil then
		if scope == "b" then
			vim.health.info("`vim.b.formatlsp = nil`: Using global fallback")
		else
			vim.health.info("`vim.g.formatlsp = nil`: Formatting with any attached language server(s)")
		end
		return true
	elseif formatlsp == "" then
		vim.health.info("`vim." .. scope .. '.formatlsp = ""`: Formatting on save disabled')
		return false
	elseif type(formatlsp) == "string" then
		vim.health.info(('`vim.%s.formatlsp = "%s"`'):format(scope, formatlsp))
		return true
	else
		vim.health.error("`vim." .. scope .. ".formatlsp` is expected to be either a string or nil")
		return false
	end
end

---@param bufnr integer
local function check_formatting_clients_attached(bufnr)
	local formatlsp = vim.b[bufnr].formatlsp or vim.g.formatlsp --[[@as string?]]
	if formatlsp == "" then
		return
	end
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
---@return boolean add_to_nobuffer
local function check_buffer(bufnr)
	if not vim.bo[bufnr].buflisted or vim.bo[bufnr].buftype ~= "" then
		return false
	end

	local continue, add_to_noformat = check_buffer_has_one_format_autocmd(bufnr)
	local _ok = continue and check_formatlsp_valid(bufnr) and check_formatting_clients_attached(bufnr)
	return add_to_noformat
end -- }}}

function M.check()
	check_formatlsp_valid()
	local noformat = vim.iter(vim.api.nvim_list_bufs())
		:filter(function(bufnr)
			return check_buffer(bufnr)
		end)
		:totable() ---@type integer[]
	if vim.tbl_isempty(noformat) then
		return
	end
	vim.health.start("Buffers without attached language servers")
	for _, bufnr in ipairs(noformat) do
		vim.health.info(get_buf_name(bufnr))
	end
end
return M
