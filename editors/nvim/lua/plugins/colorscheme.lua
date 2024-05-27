local add, now, later = MiniDeps.add, MiniDeps.now, MiniDeps.later

-- This variable will contain the last used colorscheme
-- persistent between restarts
vim.g.SCHEME = "default"

now(function()
	add("folke/tokyonight.nvim")
	vim.api.nvim_create_autocmd("VimEnter", {
		desc = "Set the colorscheme to the persistent `vim.g.SCHEME`",
		nested = true,
		callback = function()
			pcall(vim.cmd.colorscheme, vim.g.SCHEME)
		end,
	})

	vim.api.nvim_create_autocmd("ColorScheme", {
		desc = "Update `vim.g.SCHEME`",
		callback = function(params)
			vim.g.SCHEME = params.match
		end,
	})
end)
