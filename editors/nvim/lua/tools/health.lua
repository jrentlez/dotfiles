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
		if not cmd or name == cmd then
			vim.health.warn(("`%s` is not executable"):format(name), ("`%s` may not be installed"):format(name))
		else
			vim.health.warn(
				("`%s`: `%s` is not executable"):format(name, cmd),
				("`%s` may not be installed"):format(name)
			)
		end
	end
end

local M = {}
function M.check()
	vim.health.start("Language servers")
	vim.health.info("see `:checkhealth vim.lsp`")

	vim.health.start("Formatters")
	print_executable_message("stylua")
	print_executable_message("shfmt")

	vim.health.start("Linters")
	print_executable_message("shellcheck")
end
return M
