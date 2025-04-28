---@module "mini.deps"

local add, later = MiniDeps.add, MiniDeps.later

later(function()
	add("WhoIsSethDaniel/mason-tool-installer.nvim")

	local ensure_installed = vim.tbl_filter(function(server_name)
		local installed = require("spec").tool_installation_status(server_name)
		return installed == "installed-mason" or installed == "install-via-mason"
	end, require("spec"):all_specified_tools())

	require("mason-tool-installer").setup({ ensure_installed = ensure_installed, auto_update = true })
	vim.cmd("MasonToolsUpdate")
end)
