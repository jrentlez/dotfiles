---@param name string
---@param cmd? string
local function check_executable(name, cmd)
	if vim.fn.executable(cmd or name) == 1 then
		if not cmd or name == cmd then
			vim.health.ok("`" .. name .. "` is executable")
		else
			vim.health.ok("`" .. name .. "`: `" .. cmd .. "` is executable")
		end
	else
		vim.health.warn("`" .. cmd or name .. "` is not executable", "`" .. name .. "` may not be installed")
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
				"`:checkhealth vim.lsp` cannot tell whether " .. config.name or name .. " is executable or not",
				{
					"The configuration's `cmd` field is a function",
					"see `:help lspconfig-all`",
				}
			)
		end
	end

	vim.health.start("Formatters")
	check_executable("stylua")
	check_executable("shfmt")

	vim.health.start("Linters")
	check_executable("shellcheck")
end
return M
