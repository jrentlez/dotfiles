vim.keymap.set({ "n", "t" }, "<C-Space>", function()
	require("toggleterm").toggle()
end, { desc = "Terminal in vertical split" })
