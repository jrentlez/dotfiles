-- Jayvee
vim.pack.add({ "https://github.com/jvalue/jayvee.nvim.git" })

vim.schedule(function()
	-- Conflict
	vim.pack.add({ "https://github.com/TungstnBallon/conflict.nvim.git" })
	vim.keymap.set("n", "gC", "<Plug>ConflictJumpToNext", { desc = "Go to next conflict" })
	vim.keymap.set("n", "<leader>r", "<Plug>ConflictResolveAroundCursor", { desc = "Resolve conflict around cursor" })

	-- Extui
	require("vim._extui").enable({})
end)
