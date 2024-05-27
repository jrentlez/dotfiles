-- Disable icons in tty
if vim.fn.getenv("XDG_SESSION_TYPE") == "tty" then
	vim.g.have_nerd_font = false
else
	vim.g.have_nerd_font = true
end

-- Install mini.nvim
local path_package = vim.fn.stdpath("data") .. "/site"
local mini_path = path_package .. "/pack/deps/start/mini.nvim"
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
require("util")
require("plugins")
