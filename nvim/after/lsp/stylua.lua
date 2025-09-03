---@class StyluaMismatch
---@field expected string
---@field expected_end_line integer
---@field expected_start_line integer
---@field original string
---@field original_end_line integer
---@field original_start_line integer

---@class (exact) StyluaOutput
---@field file string
---@field mismatches StyluaMismatch[]

---@return integer
local function next_request_id()
	return os.time()
end

---@param capabilities lsp.ClientCapabilities
---@param callback fun(err?: lsp.InitializeError & lsp.ResponseError, result: lsp.InitializeResult)
local function supports_utf8(capabilities, callback)
	if
		capabilities.general
		and capabilities.general.positionEncodings
		and vim.list_contains(capabilities.general.positionEncodings, "utf-8")
	then
		return true
	end
	callback({
		retry = false,
		message = "stylua only supports utf-8",
		code = vim.lsp.protocol.constants.ErrorCodes.InvalidParams,
	}, { capabilities = {} })
	return false
end

---@param out vim.SystemCompleted
---@param callback fun(err?: lsp.InitializeError & lsp.ResponseError, result: lsp.InitializeResult)
local function on_stylua_version(out, callback)
	if out.code ~= 0 or out.stdout == nil then
		callback({
			retry = false,
			message = "stylua --version failed with exit code " .. out.code,
			code = out.code,
		}, { capabilities = {} })
	else
		local version = out.stdout:sub(("stylua "):len()):gsub("%s+", "")
		callback(nil, {
			capabilities = {
				documentFormattingProvider = { workDoneProgress = false },
				positionEncoding = "utf-8",
			},
			serverInfo = { name = "stylua", version = version },
		})
	end
end

---@param mismatch StyluaMismatch
---@param bufnr integer
---@return lsp.TextEdit
local function mismatch_to_text_edit(mismatch, bufnr)
	local orig_start = vim.pos(mismatch.original_start_line, 0, { buf = bufnr })
	-- NOTE: `vim.Pos` end is exclusive, `original_end_line` inclusive
	local orig_end = vim.pos(mismatch.original_end_line + 1, 0, { buf = bufnr })

	local orig_range = vim.range(orig_start, orig_end)
	local orig_lsp_range = orig_range:to_lsp("utf-8")
	return { newText = mismatch.expected, range = orig_lsp_range }
end

---@param out vim.SystemCompleted
---@param bufnr integer
---@param callback fun(err?: lsp.ResponseError, result: lsp.TextEdit[])
local function on_stylua_output(out, bufnr, callback)
	if out.stdout == nil then
		callback({
			code = out.code,
			message = out.stderr or ("stylua exited with code " .. out.code),
		}, {})
		return
	elseif out.stdout == "" then
		callback(nil, {})
		return
	end
	local output = vim.json.decode(out.stdout) ---@type StyluaOutput
	assert(output.file == "stdin")
	assert(vim.islist(output.mismatches))
	local text_edits = vim.tbl_map(function(mismatch)
		return mismatch_to_text_edit(mismatch, bufnr)
	end, output.mismatches)
	callback(nil, text_edits)
end

---@param uri lsp.DocumentUri
---@param formatting_options lsp.FormattingOptions
---@param callback fun(err?: lsp.ResponseError, result: lsp.TextEdit[])
local function run_stylua(uri, formatting_options, callback)
	local bufname = vim.uri_to_fname(uri)
	local bufnr ---@type integer?
	for _, buf in ipairs(vim.api.nvim_list_bufs()) do
		local name = vim.api.nvim_buf_get_name(buf)
		if bufname == name then
			bufnr = buf
			break
		end
	end
	bufnr = assert(bufnr)
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
			return on_stylua_output(out, bufnr, callback)
		end)
	)
	return bufnr, cmd, opts
end

---@type vim.lsp.Config
local Config = {}
function Config.cmd(dispatchers, _)
	local shutdown = false ---@type boolean

	local handlers = {}

	---@param params lsp.InitializeParams
	---@param callback fun(err?: lsp.InitializeError & lsp.ResponseError, result: lsp.InitializeResult)
	---@return boolean
	---@return integer
	function handlers.initialize(_, params, callback)
		shutdown = false
		if not supports_utf8(params.capabilities, callback) then
			return true, next_request_id()
		end
		vim.system(
			{ "stylua", "--version" },
			nil,
			vim.schedule_wrap(function(out)
				on_stylua_version(out, callback)
			end)
		)
		return true, next_request_id()
	end

	---@param callback fun(err?: lsp.ResponseError, result: vim.NIL)
	---@return boolean
	---@return integer
	function handlers.shutdown(_, _, callback)
		shutdown = true
		callback(nil, vim.NIL)
		return true, next_request_id()
	end

	---@param params lsp.DocumentFormattingParams
	---@param callback fun(err?: lsp.ResponseError, result: lsp.TextEdit[])
	---@return boolean
	---@return integer
	handlers["textDocument/formatting"] = function(_, params, callback)
		run_stylua(params.textDocument.uri, params.options, callback)
		return true, next_request_id()
	end

	---@type vim.lsp.rpc.PublicClient
	local Client = {
		notify = function(method, _)
			if method == "exit" then
				dispatchers.on_exit(0, 15)
			end
			return false
		end,
		is_closing = function()
			return shutdown
		end,
		terminate = function()
			shutdown = true
			dispatchers.on_exit(0, 0)
		end,
		request = function(method, params, callback, _)
			if shutdown then
				callback({
					code = vim.lsp.protocol.constants.ErrorCodes.InvalidRequest,
					message = "Cannot take requests after shutdown",
				})
				return false, next_request_id()
			end
			local handler = handlers[method]
			if handler then
				return handler(method, params, callback)
			end
			callback({
				code = vim.lsp.protocol.constants.ErrorCodes.MethodNotFound,
				message = "stylua does not support" .. method,
			})
			return false, next_request_id()
		end,
	}

	return Client
end
Config.filetypes = { "lua" }
Config.root_markers = { ".stylua.toml", "stylua.toml" }

return Config
