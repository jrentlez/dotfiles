local M = {}

function M.check()
	vim.health.start("Check all specified tools are installed")

	local installed_tools = require("mason-registry").get_installed_package_names() --[[@as string[] ]]
	local aliases = require("mason-lspconfig").get_mappings().lspconfig_to_package
	vim.iter(require("spec").mason):each(function(tool_name)
		local mason_name = aliases[tool_name] or tool_name
		if vim.list_contains(installed_tools, mason_name) then
			vim.health.ok(("'%s' installed via mason"):format(tool_name))
		elseif require("mason-registry").has_package(tool_name) then
			vim.health.error(
				("'%s' was not automatically installed via mason"):format(tool_name),
				"Make sure the automatic installation process in '/plugin/mason-tool-installer' works"
			)
		else
			vim.health.warn(
				("It seems '%s' is not available via mason"):format(tool_name),
				"If the tool is an LSP installed on your system, you need to specify it in the `system_lsps` list, not `mason`"
			)
		end
	end)

	vim.iter(require("spec").system_lsps):each(function(server_name)
		local lspconfig = assert(vim.lsp.config[server_name])
		if type(lspconfig.cmd) == "function" then
			vim.health.ok(("'%s' is an in-process LSP"):format(server_name))
		elseif vim.fn.executable(lspconfig.cmd[1]) == 1 then
			vim.health.ok(("'%s' installed on your system"):format(server_name))
		else
			vim.health.warn(
				("It seems '%s' is not executable on your system"):format(server_name),
				"If the LSP needs to be installed via mason, you need to specify it in the `mason` list, not `system_lsps`"
			)
		end
	end)

	local unspecified_installed = vim.iter(require("mason-registry").get_installed_packages())
		:map(
			---@param pkg Package
			function(pkg)
				local name = vim.list_contains(pkg.spec.categories, pkg.Cat.LSP)
						and require("mason-lspconfig").get_mappings().package_to_lspconfig[pkg.name]
					or pkg.name
				local specified = vim.list_contains(require("spec").mason, name)
					or vim.list_contains(require("spec").system_lsps, name)
				if specified then
					return nil
				else
					return name
				end
			end
		)
		:totable() --[[@as string[] ]]

	if vim.tbl_isempty(unspecified_installed) then
		vim.health.info("All installed tools can be found in the spec")
	else
		vim.health.warn("Some installed tools are not mentioned in the spec", unspecified_installed)
	end
end
return M
