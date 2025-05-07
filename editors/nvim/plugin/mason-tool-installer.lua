---@module "mini.deps"

local add, later = MiniDeps.add, MiniDeps.later

later(function()
	add("WhoIsSethDaniel/mason-tool-installer.nvim")

	require("mason-tool-installer").setup({ ensure_installed = require("spec").mason, auto_update = true })
	vim.cmd("MasonToolsUpdate")
end)
