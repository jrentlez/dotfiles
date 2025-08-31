vim.schedule(function()
	vim.pack.add({ "https://github.com/TungstnBallon/split-term.nvim" })
	vim.keymap.set({ "n", "t" }, "<C-Space>", "<Plug>SplitTermToggle")
end)
