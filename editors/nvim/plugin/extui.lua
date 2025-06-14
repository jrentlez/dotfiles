---@module "mini.deps"

MiniDeps.later(function()
	local success, extui = pcall(require, "vim._extui")
	if success then
		extui.enable({})
	end
end)
