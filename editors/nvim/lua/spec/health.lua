local M = {}

function M.check()
	vim.health.start("Check all specified packages are installed")

	local installed_pkgs = require("mason-registry").get_installed_packages() --[[@as Package[] ]]
	vim.iter(require("spec").mason):each(
		---@param pkg_name string
		function(pkg_name)
			if
				vim.iter(installed_pkgs):any(
					---@param pkg Package
					function(pkg)
						return pkg.name == pkg_name or vim.list_contains(pkg:get_aliases(), pkg_name)
					end
				)
			then
				vim.health.ok(("'%s' installed via mason"):format(pkg_name))
			elseif
				vim.iter(require("mason-registry").get_all_packages()):any(
					---@param pkg Package
					function(pkg)
						return pkg.name == pkg_name or vim.list_contains(pkg:get_aliases(), pkg_name)
					end
				)
			then
				vim.health.error(
					("'%s' was not automatically installed via mason"):format(pkg_name),
					"Make sure the automatic installation process in '/plugin/mason-tool-installer' works"
				)
			else
				vim.health.warn(
					("It seems '%s' is not available via mason"):format(pkg_name),
					"If the package is an LSP installed on your system, you need to specify it in the `system_lsps` list, not `mason`"
				)
			end
		end
	)

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
		vim.health.info("All installed packages can be found in the spec")
	else
		vim.health.warn("Some installed packages are not mentioned in the spec", unspecified_installed)
	end
end
return M
