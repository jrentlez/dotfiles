---Prints the appropriate error message if a program is (not) executable
---@param name string The program's name
---@param cmd? string The actual command to check
local function print_executable_message(name, cmd)
	vim.validate("name", name, "string", false)
	vim.validate("cmd", cmd, "string", true)

	if vim.fn.executable(cmd or name) == 1 then
		if not cmd or name == cmd then
			vim.health.ok(("`%s` is executable"):format(name))
		else
			vim.health.ok(("`%s`: `%s` is executable"):format(name, cmd))
		end
	else
		vim.health.warn(("`%s` is not executable"):format(cmd or name), ("`%s` may not be installed"):format(name))
	end
end

local M = {}
function M.check()
	vim.health.start("Language servers")
	vim.health.info("see `:checkhealth vim.lsp`")
	for name, v in pairs(vim.lsp._enabled_configs) do
		local config = v.resolved_config
		if config and type(config.cmd) == "function" then
			vim.health.warn(
				("`:checkhealth vim.lsp` cannot tell whether this is executable or not"):format(config.name or name),
				{
					"The configuration's `cmd` field is a function",
					("see `:help lspconfig-all`"):format(config.name or name),
				}
			)
		end
	end

	vim.health.start("Formatters")
	print_executable_message("stylua")
	print_executable_message("shfmt")

	vim.health.start("Linters")
	print_executable_message("shellcheck")
end
return M
