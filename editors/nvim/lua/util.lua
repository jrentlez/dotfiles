vim.custom = {}

vim.custom.color_name_to_hex = function(name)
	return string.format("%x", vim.api.nvim_get_color_by_name(name))
end

vim.custom.cli_cmd = function(cmd)
	vim.notify(string.format("Execute: %s", vim.inspect(cmd)))

	local handle = vim.system(cmd, {
		text = true,
		stdout = function(err, data)
			if err then
				vim.notify(err, vim.log.levels.ERROR)
			end
			if data then
				vim.notify(data, vim.log.levels.INFO)
			end
		end,
		stderr = function(err, data)
			if err then
				vim.notify(err, vim.log.levels.ERROR)
			end
			if data then
				vim.notify(data, vim.log.levels.ERROR)
			end
		end,
	})

	return handle
end
