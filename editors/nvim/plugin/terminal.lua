-- {{{ function `toggle_terminal`, helpers and state
-- {{{ state

---@type integer | nil
local buffer = nil
---@type integer | nil
local window = nil -- }}}
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
local function open_buffer_in_window()
	window = vim.api.nvim_open_win(assert(buffer), true, { vertical = vim.o.lines * 2.5 <= vim.o.columns })
	vim.wo[window].winfixbuf = true
end
local function enter_terminal()
	if not vim.bo[buffer].buftype == "terminal" then
		vim.fn.jobstart("zsh", { term = true })
	end
	vim.cmd.startinsert()
end -- }}}

local function toggle_terminal()
	if window and vim.api.nvim_win_is_valid(window) then
		assert(buffer and vim.api.nvim_buf_is_valid(buffer))
		vim.api.nvim_win_hide(window)
	else
		ensure_valid_buffer()
		open_buffer_in_window()
		enter_terminal()
	end
end -- }}}

vim.keymap.set({ "n", "t" }, "<C-Space>", toggle_terminal, { desc = "Terminal in vertical split" })
