vim.pack.add({ "https://github.com/jvalue/jayvee.nvim.git" })

-- {{{ function `goto_next_conflict_marker` and helper
-- {{{ helper

---@param lines string[]
---@return boolean
local function go_to_marker_in(lines)
	local marker_row ---@type integer?
	for idx, line in ipairs(lines) do
		if line == "=======" then
			marker_row = idx + 1
			break
		end
	end
	if marker_row then
		vim.api.nvim_win_set_cursor(0, { marker_row, 0 })
		return true
	else
		return false
	end
end -- }}}

---@param window? integer
---@return boolean
local function goto_next_conflict_marker(window)
	window = window or 0
	local buffer = vim.api.nvim_win_get_buf(window)
	local row = vim.api.nvim_win_get_cursor(window)[1]
	local lines_from_cursor_to_end = vim.api.nvim_buf_get_lines(buffer, row, -1, false)

	if go_to_marker_in(lines_from_cursor_to_end) then
		return true
	end
	local lines_from_start_to_cursor = vim.api.nvim_buf_get_lines(buffer, 0, row, false)
	return go_to_marker_in(lines_from_start_to_cursor)
end -- }}}

vim.schedule(function()
	require("vim._extui").enable({})
	vim.keymap.set("n", "gC", function()
		if not goto_next_conflict_marker() then
			vim.notify("No conflict marker found", vim.log.levels.INFO)
		end
	end, { desc = "Go to next conflict marker" })
end)
