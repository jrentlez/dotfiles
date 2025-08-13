-- {{{ check_buffer and helpers
-- {{{ Helpers

---@param bufnr integer
---@return string buf_name
local function get_buf_name(bufnr)
	local buf_name = vim.api.nvim_buf_get_name(bufnr)
	return buf_name == "" and "[No Name]" or (vim.fs.relpath(assert(vim.uv.cwd()), buf_name) or buf_name)
end

---@param bufnr integer
---@return vim.api.keyset.get_autocmds.ret[]
local function get_format_autocmds(bufnr)
	return vim.api.nvim_get_autocmds({
		id = vim.b[bufnr].format_on_save_autocmd_id,
		buffer = bufnr,
		event = "BufWritePre",
		group = vim.api.nvim_create_augroup("custom-lsp-autocmds", { clear = false }),
	})
end

---@param bufnr integer
---@return boolean has_format_autocmd
local function check_buffer_has_one_format_autocmd(bufnr)
	local num_format_autocmds = vim.tbl_count(get_format_autocmds(bufnr))
	assert(num_format_autocmds <= 1, "There is, at most, one format-on-save autocmd per buffer")

	if num_format_autocmds == 0 then
		assert(
			vim.tbl_isempty(vim.lsp.get_clients({ bufnr = bufnr })),
			"The autocmd is created on every `LspAttach` event"
		)
		return false
	end
	return true
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
		vim.health.info("`vim." .. scope .. '.formatlsp = "' .. formatlsp .. '"`')
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
	local clients = vim.lsp.get_clients({
		name = formatlsp,
		bufnr = bufnr,
	})
	if vim.tbl_isempty(clients) then
		if formatlsp then
			vim.health.warn("`" .. formatlsp .. "` is not attached to this buffer")
		else
			vim.health.error(
				"No clients attached to this buffer",
				"The format-on-save autocommand is not cleaned up properly"
			)
		end
		return
	end

	local textDocument_formatting = vim.lsp.protocol.Methods.textDocument_formatting
	local found_formatter = false
	for _, client in ipairs(clients) do
		if client:supports_method(textDocument_formatting, bufnr) then
			vim.health.ok("Formatting with `" .. client.name .. "` (id: " .. client.id .. ")")
			found_formatter = true
		else
			vim.health.warn(
				"`" .. client.name .. '` does not support `"' .. textDocument_formatting .. '"` in this buffer'
			)
		end
	end
	if not found_formatter then
		vim.health.warn("No language server with formatting capabilities attached to this buffer")
	end
end -- }}}

---@param bufnr integer
---@return boolean add_to_noformat
local function check_buffer(bufnr)
	if (not vim.bo[bufnr].buflisted) or vim.bo[bufnr].buftype ~= "" then
		return false
	end
	if not check_buffer_has_one_format_autocmd(bufnr) then
		return true
	end
	vim.health.start(get_buf_name(bufnr))
	if check_formatlsp_valid(bufnr) then
		check_formatting_clients_attached(bufnr)
	end
	return false
end -- }}}

local M = {}
function M.check()
	check_formatlsp_valid()
	local no_format_autocmd = vim.tbl_filter(check_buffer, vim.api.nvim_list_bufs())
	if vim.tbl_isempty(no_format_autocmd) then
		return
	end
	vim.health.start("Buffers without a format-on-save autocmd")
	for _, bufnr in ipairs(no_format_autocmd) do
		vim.health.info(get_buf_name(bufnr))
	end
end
return M
