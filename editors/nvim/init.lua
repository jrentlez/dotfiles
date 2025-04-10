-- Install mini.nvim
local path_package = vim.fs.joinpath(vim.fn.stdpath("data"), "/site")
local mini_path = vim.fs.joinpath(path_package, "/pack/deps/start/mini.nvim")
if not vim.uv.fs_stat(mini_path) then
	vim.cmd('echo "Installing `mini.nvim`" | redraw')
	local clone_cmd = {
		"git",
		"clone",
		"--filter=blob:none",
		"https://github.com/echasnovski/mini.nvim",
		mini_path,
	}
	local out = vim.fn.system(clone_cmd)
	if vim.v.shell_error ~= 0 then
		error("Error cloning mini.nvim\n" .. out)
	end
	vim.cmd("packadd mini.nvim | helptags ALL")
end

-- Plugin manager
require("mini.deps").setup({ path = { package = path_package } })

-- Enable project local configuration
vim.o.exrc = true

-- Use space as the one and only true Leader key
vim.g.mapleader = " "
