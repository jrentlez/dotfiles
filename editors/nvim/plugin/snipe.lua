---@module "mini.deps"

local add, later = MiniDeps.add, MiniDeps.later

later(function()
	add("leath-dub/snipe.nvim")

	require("snipe").setup({
		navigate = { cancel_snipe = { "<esc>", "q" } },
		preselect_current = true,
		ui = {
			open_win_override = {
				title = " Buffers ",
			},
		},
	})
	vim.keymap.set("n", "<leader>a", require("snipe").open_buffer_menu, { desc = 'require("snipe").open_buffer_menu' })
end)
