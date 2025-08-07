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

local function goto_next_conflict_marker()
	local row = unpack(vim.api.nvim_win_get_cursor(0))
	local lines = vim.api.nvim_buf_get_lines(0, row, -1, false)

	if go_to_marker_in(lines) then
		return
	end
	lines = vim.api.nvim_buf_get_lines(0, 0, row, false)
	if go_to_marker_in(lines) then
		return
	end
end -- }}}

vim.schedule(function()
	require("vim._extui").enable({})
	vim.keymap.set("n", "gC", goto_next_conflict_marker, { desc = "Go to next conflict marker" })
end)
