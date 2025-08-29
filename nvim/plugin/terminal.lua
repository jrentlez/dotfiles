-- {{{ function `toggle_terminal`, helpers and state
-- {{{ state

local buffer = nil ---@type integer | nil
local window = nil ---@type integer | nil
local enter_terminal_mode = true ---@type boolean -- }}}
-- {{{ helpers

local function ensure_valid_buffer()
	if buffer and vim.api.nvim_buf_is_valid(buffer) then
		return
	end
	buffer = vim.api.nvim_create_buf(false, false)
	vim.api.nvim_create_autocmd("TermClose", {
		desc = "Autoclose buffer on exit",
		group = vim.api.nvim_create_augroup("autoclose-toggleterm", { clear = true }),
		buffer = buffer,
		callback = function(args)
			enter_terminal_mode = true
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
local function show_buffer()
	assert(not window or not vim.api.nvim_win_is_valid(window), "window is not shown")
	window = vim.api.nvim_open_win(assert(buffer), true, { vertical = vim.o.columns > 130 })
	vim.wo[window].winfixbuf = true
end
local function enter_terminal()
	if vim.bo[buffer].buftype ~= "terminal" then
		vim.fn.jobstart("zsh", { term = true })
	end
	if enter_terminal_mode then
		vim.cmd.startinsert()
	end
end -- }}}

local function toggle_terminal()
	if window and vim.api.nvim_win_is_valid(window) then
		assert(buffer and vim.api.nvim_buf_is_valid(buffer))
		enter_terminal_mode = vim.fn.mode():sub(1, 1) == "t"
		vim.api.nvim_win_hide(window)
	else
		ensure_valid_buffer()
		show_buffer()
		enter_terminal()
	end
end -- }}}

vim.keymap.set({ "n", "t" }, "<C-Space>", toggle_terminal, { desc = "Toggle terminal" })
