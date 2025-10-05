local buffer ---@type integer?
local window ---@type integer?
local enter_terminal_mode = true ---@type boolean

local function ensure_valid_buffer()
	if buffer and vim.api.nvim_buf_is_valid(buffer) then
		return
	end
	buffer = vim.api.nvim_create_buf(false, false)
	vim.api.nvim_create_autocmd("TermClose", {
		group = vim.api.nvim_create_augroup("autoclose-toggleterm", { clear = false }),
		buffer = buffer,
		callback = function(args)
			assert(buffer == args.buf)
			enter_terminal_mode = true
			if window and vim.api.nvim_win_is_valid(window) then
				vim.api.nvim_win_close(window, false)
				window = nil
			end
			if vim.api.nvim_buf_is_valid(buffer) then
				vim.api.nvim_buf_delete(buffer, {})
				buffer = nil
			end
		end,
	})
end
local function show_buffer()
	assert(not window or not vim.api.nvim_win_is_valid(window), "window is not shown")
	local vertical = vim.g.splitterm_vertical
	if type(vertical) == "function" then
		vertical = vertical()
	end
	if vertical == nil then
		vertical = false
	end
	window = vim.api.nvim_open_win(assert(buffer), true, { vertical = vertical, win = -1 })
	vim.wo[window].winfixbuf = true
end
local function enter_terminal()
	if vim.bo[buffer].buftype ~= "terminal" then
		vim.fn.jobstart(vim.g.splitterm_shell or vim.env.NVIM_SHELL or vim.o.shell, { term = true })
	end
	if enter_terminal_mode then
		vim.cmd.startinsert()
	end
end
local function toggle()
	if window and vim.api.nvim_win_is_valid(window) then
		assert(buffer and vim.api.nvim_buf_is_valid(buffer))
		enter_terminal_mode = vim.fn.mode():sub(1, 1) == "t"
		vim.api.nvim_win_hide(window)
	else
		ensure_valid_buffer()
		show_buffer()
		enter_terminal()
	end
end

vim.keymap.set({ "n", "t" }, "<C-Space>", toggle)
