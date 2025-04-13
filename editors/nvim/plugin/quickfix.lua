---@module "mini.deps"

local add, later = MiniDeps.add, MiniDeps.later

later(function()
	add("yorickpeterse/nvim-pqf")

	require("pqf").setup()
end)
