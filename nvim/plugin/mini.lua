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
	--stylua: ignore start
	vim.keymap.set({ "n", "x", "o" }, "[X", function() goto_conflict("first") end)
	vim.keymap.set({ "n", "x", "o" }, "]X", function() goto_conflict("last") end)
	vim.keymap.set({ "n", "x", "o" }, "[x", function() goto_conflict("backward") end)
	vim.keymap.set({ "n", "x", "o" }, "]x", function() goto_conflict("forward") end)
	--stylua: ignore end

	require("mini.pick").setup({ source = { show = require("mini.pick").default_show } })
	vim.keymap.set("n", "<leader><leader>", "<cmd>Pick buffers<cr>")
	vim.keymap.set("n", "<leader>s.", "<cmd>Pick resume<cr>")
	vim.keymap.set("n", "<leader>sf", "<cmd>Pick files<cr>")
	vim.keymap.set("n", "<leader>sg", "<cmd>Pick grep_live<cr>")
	vim.keymap.set("n", "<leader>sh", "<cmd>Pick help<cr>")
	vim.keymap.set("n", "<leader>sr", function()
		MiniPick.start({ source = { items = vim.v.oldfiles, name = "v:oldfiles" } })
	end)
end)
