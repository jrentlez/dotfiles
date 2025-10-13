vim.api.nvim_create_autocmd("PackChanged", {
	group = vim.api.nvim_create_augroup("nvim-treesitter-update-parsers", { clear = true }),
	callback = function(args)
		local kind = args.data.kind --[[@as "install" | "update" | "delete"]]
		local spec = args.data.spec --[[@as vim.pack.SpecResolved]]
		if spec.name == "nvim-treesitter" and kind ~= "delete" then
			vim.cmd("TSUpdate")
		end
	end,
})
vim.pack.add({ {
	src = "https://github.com/nvim-treesitter/nvim-treesitter",
	version = "main",
} }, { load = true })

vim.api.nvim_create_autocmd("FileType", {
	group = vim.api.nvim_create_augroup("nvim-treesitter-buffer-setup", { clear = true }),
	callback = function(args)
		if pcall(vim.treesitter.start, args.buf) then
			vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
		elseif args.match ~= "" then
			local language = assert(vim.treesitter.language.get_lang(args.match)) ---@type string
			require("nvim-treesitter").install(language, { summary = true }):await(function(err)
				if err then
					error(err, vim.log.levels.ERROR)
				elseif pcall(vim.treesitter.start, args.buf) then
					vim.treesitter.start(args.buf)
					vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
				end
			end)
		end
	end,
})

vim.schedule(function()
	local required_parsers = vim.tbl_filter(function(parser)
		return not vim.list_contains(require("nvim-treesitter").get_installed(), parser)
	end, { "c", "lua", "markdown", "markdown_inline", "query", "vim", "vimdoc", "comment", "diff" })
	if not vim.tbl_isempty(required_parsers) then
		require("nvim-treesitter").install(required_parsers, { summary = true })
	end
end)
