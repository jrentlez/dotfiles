---@module "mini.deps"

local add, later = MiniDeps.add, MiniDeps.later

later(function()
	add({ source = "TungstnBallon/conflict.nvim" })

	vim.keymap.set("n", "gC", "<Plug>ConflictJumpToNext", { desc = "Jump to the next conflict in the current buffer" })

	vim.keymap.set(
		"n",
		"grh",
		"<Plug>ConflictResolveAroundCursor",
		{ desc = "Resolve the conflict around the current cursor position" }
	)
end)
