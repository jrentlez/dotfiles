MiniDeps.later(function()
	MiniDeps.add("numToStr/Navigator.nvim")
	local nvmap = function(lhs, rhs, desc)
		vim.keymap.set({ "n", "t", "i", "v", "x" }, lhs, rhs, { desc = desc })
	end
	---@diagnostic disable-next-line: missing-parameter
	require("Navigator").setup()
	nvmap("<C-h>", "<cmd>NavigatorLeft<cr>", "Move focus left")
	nvmap("<C-l>", "<cmd>NavigatorRight<cr>", "Move focus right")
	nvmap("<C-k>", "<cmd>NavigatorUp<cr>", "Move focus up")
	nvmap("<C-j>", "<cmd>NavigatorDown<cr>", "Move focus down")
end)
