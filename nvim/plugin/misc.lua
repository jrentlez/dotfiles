vim.pack.add({ "https://github.com/jvalue/jayvee.nvim.git" })

-- {{{ function `goto_next_conflict_marker`

local function goto_first_conflict_marker_row()
	local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
	local row ---@type integer?
	for line_idx_one_based, line in ipairs(lines) do
		if line == "=======" then
			row = line_idx_one_based
			break
		end
	end
	if row then
		vim.api.nvim_win_set_cursor(0, { row, 0 })
	else
		vim.notify("No conflict marker found", vim.log.levels.INFO)
	end
end -- }}}

vim.schedule(function()
	require("vim._extui").enable({})
	vim.keymap.set("n", "gC", goto_first_conflict_marker_row, { desc = "Go to first conflict marker" })
end)
