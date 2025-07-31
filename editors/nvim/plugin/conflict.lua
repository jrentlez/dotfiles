vim.schedule(function()
	vim.pack.add({ "https://github.com/TungstnBallon/conflict.nvim.git" })

	vim.keymap.set("n", "gC", "<Plug>ConflictJumpToNext", { desc = "Jump to the next conflict in the current buffer" })

	vim.keymap.set(
		"n",
		"grh",
		"<Plug>ConflictResolveAroundCursor",
		{ desc = "Resolve the conflict around the current cursor position" }
	)
end)
