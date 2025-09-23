vim.schedule(function()
	vim.pack.add({
		"https://github.com/nvim-mini/mini.diff",
		"https://github.com/nvim-mini/mini-git",
		"https://github.com/nvim-mini/mini.bracketed",
		"https://github.com/nvim-mini/mini.pick",
	})

	require("mini.git").setup()

	require("mini.diff").setup()
	vim.keymap.set("n", "zV", MiniDiff.toggle_overlay)

	local goto_conflict = require("mini.bracketed").conflict
	vim.keymap.set({ "n", "x", "o" }, "[X", function() goto_conflict("first") end)
	vim.keymap.set({ "n", "x", "o" }, "]X", function() goto_conflict("last") end)
	vim.keymap.set({ "n", "x", "o" }, "[x", function() goto_conflict("backward") end)
	vim.keymap.set({ "n", "x", "o" }, "]x", function() goto_conflict("forward") end)

	require("mini.pick").setup({ source = { show = require("mini.pick").default_show } })
	vim.keymap.set("n", "<leader><leader>", MiniPick.builtin.buffers)
	vim.keymap.set("n", "<leader>s.", MiniPick.builtin.resume)
	vim.keymap.set("n", "<leader>sf", MiniPick.builtin.files)
	vim.keymap.set("n", "<leader>sg", MiniPick.builtin.grep_live)
	vim.keymap.set("n", "<leader>sh", MiniPick.builtin.help)
	--stylua: ignore start
	vim.keymap.set("n", "<leader>sr", function()
		MiniPick.start({ source = { items = vim.v.oldfiles, name = "v:oldfiles" } })
	end)
	--stylua: ignore end
end)
