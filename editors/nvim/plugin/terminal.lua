---@type integer | nil
local buffer = nil
---@type integer | nil
local window = nil

--- Toggle a terminal window with consistent contents
local function toggle_terminal()
	if window and vim.api.nvim_win_is_valid(window) then
		assert(buffer and vim.api.nvim_buf_is_valid(buffer))
		vim.api.nvim_win_hide(window)
		return
	end

	local old_buffer = vim.api.nvim_get_current_buf()

	if not buffer or not vim.api.nvim_buf_is_valid(buffer) then
		buffer = vim.api.nvim_create_buf(false, false)
		vim.api.nvim_create_autocmd("TermClose", {
			desc = "Autoclose buffer on exit",
			group = vim.api.nvim_create_augroup("autoclose-toggleterm", { clear = true }),
			buffer = buffer,
			callback = function(args)
				if window and vim.api.nvim_win_is_valid(window) then
					vim.api.nvim_win_close(window, false)
					window = nil
				end
				if vim.api.nvim_buf_is_valid(args.buf) then
					vim.api.nvim_buf_delete(args.buf, {})
					buffer = nil
				end
			end,
		})
	end

	local vertical = vim.o.lines * 2.5 <= vim.o.columns
	window = vim.api.nvim_open_win(buffer, true, { vertical = vertical })
	vim.wo[window].winfixbuf = true

	if vim.bo[buffer].buftype == "terminal" then
		vim.cmd.startinsert()
		return
	end

	local cwd, errmsg, errname = vim.uv.cwd()
	if not cwd then
		error(errname .. ": " .. errmsg)
	end

	local new_cwd = nil
	local old_buffer_path = vim.fs.normalize(vim.api.nvim_buf_get_name(old_buffer))
	if not vim.fs.relpath(vim.fs.normalize(cwd), old_buffer_path) then
		new_cwd = vim.fs.dirname(old_buffer_path)
	end

	vim.fn.jobstart("zsh", { term = true, cwd = new_cwd })
	vim.cmd.startinsert()
end

vim.keymap.set({ "n", "t" }, "<C-Space>", toggle_terminal, { desc = "Terminal in vertical split" })
