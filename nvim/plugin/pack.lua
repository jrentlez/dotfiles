vim.api.nvim_create_user_command("PackUpdate", function()
	vim.pack.update()
end, { desc = "Update plugins" })

vim.api.nvim_create_user_command("PackClean", function()
	local inactive_names = vim.tbl_map(function(plugin)
		return not plugin.active and plugin.spec.name or nil
	end, vim.pack.get()) ---@type string[]

	if vim.tbl_isempty(inactive_names) then
		vim.print("Nothing to clean")
		return
	end

	local message = "Delete these inactive plugins?\n\n"
	for _, inactive_name in ipairs(inactive_names) do
		message = message .. inactive_name .. "\n"
	end

	if vim.fn.confirm(message) == 1 then
		vim.pack.del(inactive_names)
	end
end, { desc = "Delete inactive plugins" })
