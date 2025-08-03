-- Jayvee
vim.pack.add({ "https://github.com/jvalue/jayvee.nvim.git" })

vim.schedule(function()
	-- Conflict
	vim.pack.add({ "https://github.com/TungstnBallon/conflict.nvim.git" })
	vim.keymap.set("n", "gC", "<Plug>ConflictJumpToNext", { desc = "Jump to the next conflict in the current buffer" })
	vim.keymap.set(
		"n",
		"grh",
		"<Plug>ConflictResolveAroundCursor",
		{ desc = "Resolve the conflict around the current cursor position" }
	)

	-- Extui
	require("vim._extui").enable({})
end)
