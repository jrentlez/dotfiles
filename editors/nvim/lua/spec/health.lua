local M = {}

function M.check()
	vim.health.start("Check all specified tools are installed")

	vim.iter(require("spec"):all_specified_tools()):each(function(tool_name)
		local installed = require("spec").tool_installation_status(tool_name)
		if not installed then
			vim.health.warn(
				("It seems '%s' is not installed on your system or through mason"):format(tool_name),
				"Make sure the automatic installation process in '/plugin/mason-tool-installer' works"
			)
		elseif installed == "installed-mason" then
			vim.health.ok(("'%s' installed via mason"):format(tool_name))
		elseif installed == "installed-system" then
			vim.health.ok(("'%s' installed locally"):format(tool_name))
		elseif installed == "installed-in-process" then
			vim.health.ok(("'%s' is an in-process LSP"):format(tool_name))
		elseif installed == "install-via-mason" then
			vim.health.error(
				("'%s' was not automatically installed via mason"):format(tool_name),
				"Make sure the automatic installation process in '/plugin/mason-tool-installer' works"
			)
		else
			error("Unreachable")
		end
	end)

	local unspecified_installed = vim.iter(require("mason-registry").get_installed_packages())
		:map(
			---@param pkg Package
			function(pkg)
				local name = vim.list_contains(pkg.spec.categories, pkg.Cat.LSP)
						and require("mason-lspconfig").get_mappings().mason_to_lspconfig[pkg.name]
					or pkg.name
				if vim.list_contains(require("spec"):all_specified_tools(), name) then
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
