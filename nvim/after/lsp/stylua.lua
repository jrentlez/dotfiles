---@param capabilities lsp.ClientCapabilities
---@return boolean
local function client_supports_utf8(capabilities)
	return capabilities.general
			and capabilities.general.positionEncodings
			and vim.list_contains(capabilities.general.positionEncodings, "utf-8")
		or false
end

---@param callback fun(error?: string, version?: string)
local function get_stylua_version(callback)
	vim.system(
		{ "stylua", "--version" },
		nil,
		vim.schedule_wrap(function(out)
			if out.code ~= 0 or out.stdout == nil then
				local error = out.stderr or ("stylua --version failed with exit code " .. out.code)
				callback(error, nil)
			else
				local version = out.stdout:sub(("stylua "):len()):gsub("%s+", "")
				callback(nil, version)
			end
		end)
	)
end

---@param bufnr integer
---@param mismatch {expected: string, expected_end_line: integer, expected_start_line: integer,
---                 original: string, original_end_line: integer, original_start_line: integer}
---@return lsp.TextEdit
local function mismatch_to_text_edit(bufnr, mismatch)
	local orig_start = vim.pos(mismatch.original_start_line, 0, { buf = bufnr })
	-- NOTE: `vim.Pos` end is exclusive, `original_end_line` inclusive
	local orig_end = vim.pos(mismatch.original_end_line + 1, 0, { buf = bufnr })

	local orig_range = vim.range(orig_start, orig_end)
	local orig_lsp_range = orig_range:to_lsp("utf-8")
	return { newText = mismatch.expected, range = orig_lsp_range }
end

---@param uri lsp.DocumentUri
---@return integer bufnr
---@return string bufname
local function resolve(uri)
	local bufname = vim.uri_to_fname(uri)
	local bufnr ---@type integer?
	for _, buf in ipairs(vim.api.nvim_list_bufs()) do
		local name = vim.api.nvim_buf_get_name(buf)
		if bufname == name then
			bufnr = buf
			break
		end
	end
	return assert(bufnr), bufname
end
---@param uri lsp.DocumentUri
---@param formatting_options lsp.FormattingOptions
---@param callback fun(bufnr: integer, mismatches: StyluaMismatch[])
local function run_stylua(uri, formatting_options, callback)
	local bufnr, bufname = resolve(uri)

	local cwd = vim.fs.root(bufname, { ".stylua.toml", "stylua.toml" }) or vim.fn.getcwd(-1, -1)
	local indent_type = formatting_options.insertSpaces and "Spaces" or "Tabs"
	local indent_width = formatting_options.tabSize
	local cmd = {
		"stylua",
		"--check",
		"--output-format=JSON",
		"--respect-ignores",
		"--stdin-filepath",
		bufname,
		"--indent-type",
		indent_type,
		"--indent-width",
		tostring(indent_width),
		"-",
	}
	local opts = { cwd = cwd, stdin = vim.lsp._buf_get_full_text(bufnr), text = true }
	vim.system(
		cmd,
		opts,
		vim.schedule_wrap(function(out)
			assert(out.stdout)
			if out.stdout == "" then
				callback(bufnr, {})
			else
				local output = vim.json.decode(out.stdout)
				callback(bufnr, {})
				assert(output.file == "stdin")
				assert(vim.islist(output.mismatches))
				callback(bufnr, output.mismatches)
			end
		end)
	)
end

---@type table<string, fun(method: string, params: any, callback: fun(err?: lsp.ResponseError, result: any))>
local handlers = {}

---@param params lsp.InitializeParams
---@param callback fun(err?: lsp.InitializeError & lsp.ResponseError, result: lsp.InitializeResult)
function handlers.initialize(_, params, callback)
	if not client_supports_utf8(params.capabilities) then
		callback({
			retry = false,
			message = "stylua only supports utf-8",
			code = vim.lsp.protocol.constants.ErrorCodes.InvalidParams,
		}, { capabilities = {} })
		return
	end
	get_stylua_version(function(err, version)
		if err then
			local code = vim.lsp.protocol.constants.ErrorCodes.RequestFailed
			callback({ retry = false, message = err, code = code }, { capabilities = {} })
		else
			callback(nil, {
				capabilities = {
					documentFormattingProvider = { workDoneProgress = false },
					positionEncoding = "utf-8",
				},
				serverInfo = { name = "stylua", version = version },
			})
		end
	end)
end

---@param params lsp.DocumentFormattingParams
---@param callback fun(err?: lsp.ResponseError, result: lsp.TextEdit[])
handlers["textDocument/formatting"] = function(_, params, callback)
	run_stylua(params.textDocument.uri, params.options, function(bufnr, mismatches)
		local text_edits = vim.tbl_map(function(mismatch)
			return mismatch_to_text_edit(bufnr, mismatch)
		end, mismatches)
		callback(nil, text_edits)
	end)
end

---@param handlers table<string, fun(method: string, params: any, callback: fun(err?: lsp.ResponseError, result: any))>
---@return fun(dispatchers: vim.lsp.rpc.Dispatchers): vim.lsp.rpc.PublicClient
local function Server(handlers)
	---@param dispatchers vim.lsp.rpc.Dispatchers
	return function(dispatchers)
		---@type boolean
		local shutdown = false

		if handlers.shutdown == nil then
			---@param callback fun(err?: lsp.ResponseError, result: vim.NIL)
			function handlers.shutdown(_, _, callback)
				shutdown = true
				callback(nil, vim.NIL)
			end
		end

		---@type vim.lsp.rpc.PublicClient
		local Client = {
			notify = function(method, _)
				if method == "exit" then
					shutdown = true
					dispatchers.on_exit(0, 15)
				end
				return not shutdown
			end,
			is_closing = function()
				return shutdown
			end,
			terminate = function()
				shutdown = true
				dispatchers.on_exit(0, 0)
			end,
			request = function(method, params, callback, notify_reply_callback)
				if shutdown then
					callback({
						code = vim.lsp.protocol.constants.ErrorCodes.InvalidRequest,
						message = "Cannot take requests after shutdown",
					})
					return false, nil
				end
				local request_id = os.time()
				local handler = handlers[method]
				if handler ~= nil then
					handler(method, params, callback)
				else
					callback({
						code = vim.lsp.protocol.constants.ErrorCodes.MethodNotFound,
						message = method .. " not supported",
					})
				end
				if notify_reply_callback then
					notify_reply_callback(request_id)
				end
				return true, request_id
			end,
		}

		return Client
	end
end

---@type vim.lsp.Config
local Config = {
	cmd = Server(handlers),
	filetypes = { "lua" },
	root_markers = { ".stylua.toml", "stylua.toml" },
}
return Config
