---@type table<vim.lsp.protocol.Method, fun(method: vim.lsp.protocol.Method, params: table?, callback: fun(err?: lsp.ResponseError, result: lsp.LSPAny), notify_reply_callback?: fun(message_id: integer)):boolean,integer?>
local handlers = {}

---@type boolean
local closing = false

---@type lsp.URI?
local root_uri

local function generate_request_id()
	return os.time()
end

---@param params lsp.InitializeParams
---@param callback fun(err?: lsp.InitializeError, result?: lsp.InitializeResult)
handlers[vim.lsp.protocol.Methods.initialize] = function(_, params, callback, _)
	if params.rootUri and params.rootUri ~= vim.NIL then
		root_uri = params.rootUri
	elseif params.rootPath and params.rootPath ~= vim.NIL then
		root_uri = vim.uri_from_fname(params.rootPath)
	end

	local result = vim.fn.executable("stylua") == 1
			and function()
				callback(nil, {
					serverInfo = { name = "stylua_fmt", version = "0.1.0" },
					capabilities = {
						documentFormattingProvider = { workDoneProgress = false },
						documentRangeFormattingProvider = { workDoneProgress = false },
					},
				})
			end
		or function()
			callback({ retry = false })
		end

	vim.schedule(result)
	return true, generate_request_id()
end

---@class StyluaMismatch
---@field expected string
---@field expected_end_line number
---@field expected_start_line number
---@field original string
---@field original_end_line number
---@field original_start_line number

---@param mismatch StyluaMismatch
---@return lsp.TextEdit
local function mismatch_to_text_edit(mismatch)
	return {
		range = {
			start = { line = mismatch.original_start_line, character = 0 },
			-- NOTE: `lsp.Range` end is exclusive, `original_end_line` inclusive
			["end"] = { line = mismatch.original_end_line + 1, character = 0 },
		},
		newText = mismatch.expected,
	}
end

---@param uri lsp.URI
---@param opts lsp.FormattingOptions
---@param range? lsp.Range
---@param on_done fun(err?: lsp.ResponseError, result?: lsp.TextEdit[])
local function stylua_format(uri, opts, range, on_done)
	local bufnr = vim.uri_to_bufnr(uri)
	local cmd = {
		"stylua",
		"--search-parent-directories",
		"--check",
		"--output-format=JSON",
		"--stdin-filepath",
		uri,
		"--indent-width",
		opts.tabSize,
		"--indent-type",
		opts.insertSpaces and "Spaces" or "Tabs",
	}

	if range then
		local start_offset = vim.api.nvim_buf_get_offset(bufnr, range.start.line) + 1 + range.start.character
		table.insert(cmd, "--range-start")
		table.insert(cmd, start_offset)
		local end_offset = vim.api.nvim_buf_get_offset(bufnr, range["end"].line) + 1 + range["end"].character
		table.insert(cmd, "--range-end")
		table.insert(cmd, end_offset)
	end

	table.insert(cmd, "-")

	vim.system(cmd, {
		cwd = root_uri and vim.uri_to_fname(root_uri) or vim.fs.dirname(vim.uri_to_fname(uri)),
		stdin = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false),
		text = true,
	}, function(done)
		if done.code == 0 then
			on_done(nil, nil)
		elseif done.code == 1 then
			on_done(
				nil,
				vim.tbl_map(
					mismatch_to_text_edit,
					vim
						.json
						.decode(assert(done.stdout)) --[[@as {file: "stdin", mismatches: StyluaMismatch[]}]]
						.mismatches
				)
			)
		else
			on_done({
				code = done.code,
				message = ("stylua exited with code %d: %s"):format(done.code, done.stderr),
			})
		end
	end)
end

---@param params lsp.DocumentFormattingParams
---@param callback fun(err?: lsp.ResponseError, result?: lsp.TextEdit[])
handlers[vim.lsp.protocol.Methods.textDocument_formatting] = function(_, params, callback, _)
	stylua_format(params.textDocument.uri, params.options, nil, callback)
	return true, generate_request_id()
end

---@param params lsp.DocumentRangeFormattingParams
---@param callback fun(err?: lsp.ResponseError, result?: lsp.TextEdit[])
handlers[vim.lsp.protocol.Methods.textDocument_rangeFormatting] = function(_, params, callback, _)
	stylua_format(params.textDocument.uri, params.options, params.range, callback)
	return true, generate_request_id()
end

handlers.shutdown = function(_, _, callback, _)
	vim.schedule(function()
		callback(nil, nil)
	end)
	return true, generate_request_id()
end

---@type vim.lsp.Config
return {
	---@param dispatchers vim.lsp.rpc.Dispatchers
	---@return vim.lsp.rpc.PublicClient
	cmd = function(dispatchers)
		return {
			request = function(method, params, callback, notify_callback)
				if handlers[method] then
					return handlers[method](method, params, callback, notify_callback)
				else
					return false, nil
				end
			end,
			notify = function(method, _)
				if method == "exit" then
					-- code 0 (success), signal 15 (SIGTERM)
					dispatchers.on_exit(0, 15)
				end
				return true
			end,
			is_closing = function()
				return closing
			end,
			terminate = function()
				closing = true
			end,
		}
	end,
	filetypes = { "lua" },
	root_markers = { ".stylua.toml", "stylua.toml" },
}
