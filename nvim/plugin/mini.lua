vim.pack.add({ "https://github.com/nvim-mini/mini.nvim" }, { load = true })

require("mini.files").setup({ content = { prefix = function() end } })
vim.keymap.set("n", "<leader>f", function()
	local ok, err = pcall(MiniFiles.open, vim.api.nvim_buf_get_name(0))
	if not ok then
		vim.notify(assert(err), vim.log.levels.WARN)
		MiniFiles.open()
	end
end)

vim.schedule(function()
	require("mini.git").setup()

	require("mini.diff").setup()
	vim.keymap.set("n", "zV", MiniDiff.toggle_overlay)

	local goto_conflict = require("mini.bracketed").conflict
	--stylua: ignore start
	vim.keymap.set({ "n", "x", "o" }, "[X", function() goto_conflict("first") end)
	vim.keymap.set({ "n", "x", "o" }, "]X", function() goto_conflict("last") end)
	vim.keymap.set({ "n", "x", "o" }, "[x", function() goto_conflict("backward") end)
	vim.keymap.set({ "n", "x", "o" }, "]x", function() goto_conflict("forwards") end)
	--stylua: ignore end

	local pick = require("mini.pick")
	pick.setup({ source = { show = pick.default_show } })
	vim.ui.select = MiniPick.ui_select
	vim.keymap.set("n", "<leader><leader>", MiniPick.builtin.buffers)
	vim.keymap.set("n", "<leader>s.", MiniPick.builtin.resume)
	vim.keymap.set("n", "<leader>sf", MiniPick.builtin.files)
	vim.keymap.set("n", "<leader>sg", MiniPick.builtin.grep_live)
	vim.keymap.set("n", "<leader>sh", MiniPick.builtin.help)
	vim.keymap.set("n", "<leader>sr", function()
		pick.start({ source = { items = vim.v.oldfiles, name = "v:oldfiles" } })
	end)
end)
