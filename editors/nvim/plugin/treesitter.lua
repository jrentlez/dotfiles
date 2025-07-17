--- Ensure a buffer has its appropriate parser installed
---@param bufnr integer The buffer to check
---@param on_installed fun() Called once the parser is installed. If there is no appropriate parser for the buffer, `on_installed` is never called.
local function ensure_installed(bufnr, on_installed)
	local language = assert(
		vim.treesitter.language.get_lang(vim.bo[bufnr].filetype),
		"Only returns nil if filetype is '' which it never is"
	)
	if vim.list_contains(require("nvim-treesitter").get_installed(), language) then
		on_installed()
	elseif vim.list_contains(require("nvim-treesitter").get_available(), language) then
		require("nvim-treesitter").install(language, { summary = true }):await(function(err)
			if err then
				error(err, vim.log.levels.ERROR)
			else
				on_installed()
			end
		end)
	end
end

require("mini.deps").now(function()
	vim.api.nvim_create_autocmd("PackChanged", {
		group = vim.api.nvim_create_augroup("nvim-treesitter-update-parsers", { clear = true }),
		callback = function(args)
			local kind = args.data.kind --[[@as "install" | "update" | "delete"]]
			local spec = args.data.spec --[[@as vim.pack.SpecResolved]]
			if spec.name == "nvim-treesitter" and (kind == "install" or kind == "update") then
				require("nvim-treesitter").update({ summary = true })
			end
		end,
		desc = "Update treesitter parsers",
	})
	vim.pack.add({ {
		src = "https://github.com/nvim-treesitter/nvim-treesitter.git",
		version = "main",
	} })

	vim.api.nvim_create_autocmd("FileType", {
		group = vim.api.nvim_create_augroup("nvim-treesitter-buffer-setup", { clear = true }),
		callback = function(args)
			ensure_installed(args.buf, function()
				vim.treesitter.start(args.buf)
				vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
			end)
		end,
		desc = "Ensure the appropriate parser is installed and start it",
	})
end)

require("mini.deps").later(function()
	local installed = require("nvim-treesitter").get_installed()
	local required_parsers = vim.iter({
		"c",
		"lua",
		"markdown",
		"markdown_inline",
		"query",
		"vim",
		"vimdoc",
		"comment",
		"diff",
	})
		:filter(function(parser)
			return not vim.list_contains(installed, parser)
		end)
		:totable()
	require("nvim-treesitter").install(required_parsers, { summary = true })
end)
