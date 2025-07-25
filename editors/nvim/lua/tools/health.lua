local M = {}

function M.check()
	vim.health.start("Check all specified tools are installed")

	local installed_packages = require("mason-registry").get_installed_packages() --[[@as Package[] ]]
	vim.iter(require("tools").mason):each(
		---@param tool_name string
		function(tool_name)
			if
				vim.iter(installed_packages):any(
					---@param package Package
					function(package)
						return package.name == tool_name or vim.list_contains(package:get_aliases(), tool_name)
					end
				)
			then
				vim.health.ok(("`%s` installed via mason"):format(tool_name))
			elseif
				vim.iter(require("mason-registry").get_all_packages()):any(
					---@param pkg Package
					function(pkg)
						return pkg.name == tool_name or vim.list_contains(pkg:get_aliases(), tool_name)
					end
				)
			then
				vim.health.error(
					("`%s` was not automatically installed via mason"):format(tool_name),
					"Make sure the automatic installation process in `/plugin/lsp.lua` works"
				)
			else
				vim.health.warn(
					("It seems `%s` is not available via mason"):format(tool_name),
					"If the package is an LSP installed on your system, you need to specify it in the `system_lsps` list, not `mason`"
				)
			end
		end
	)

	vim.iter(require("tools").system_lsps):each(function(server_name)
		local lsp_config = assert(vim.lsp.config[server_name])
		if type(lsp_config.cmd) == "function" then
			vim.health.warn(
				("Cannot determine whether `%s` is installed"):format(server_name),
				"The configuration's `cmd` field is a lua function",
				("`%s` may be an in-process lsp"):format(server_name)
			)
		elseif vim.fn.executable(lsp_config.cmd[1]) == 1 then
			vim.health.ok(("`%s` installed on your system"):format(server_name))
		else
			vim.health.warn(
				("It seems `%s` is not executable on your system"):format(server_name),
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
				local specified = vim.list_contains(require("tools").mason, name)
					or vim.list_contains(require("tools").system_lsps, name)
				if specified then
					return nil
				else
					return name
				end
			end
		)
		:totable() --[[@as string[] ]]

	if vim.tbl_isempty(unspecified_installed) then
		vim.health.info("All installed packages can be found in the spec")
	else
		vim.health.warn("Some installed packages are not mentioned in the spec", unspecified_installed)
	end
end
return M
