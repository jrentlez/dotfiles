vim.pack.add({ "https://github.com/echasnovski/mini.nvim" })

-- {{{ mini.notify
require("mini.notify").setup()
vim.notify = MiniNotify.make_notify() -- }}}
-- {{{ mini.files
require("mini.files").setup({ content = { prefix = function() end } })
vim.keymap.set("n", "<leader>f", function()
	MiniFiles.open(vim.api.nvim_buf_get_name(0))
end, { desc = "Open file explorer" }) -- }}}

vim.schedule(function()
	local function nmap(lhs, rhs, desc)
		vim.keymap.set("n", lhs, rhs, { desc = desc })
	end
	-- {{{ mini.bufremove
	require("mini.bufremove").setup()
	nmap("<leader>q", MiniBufremove.delete, "Delete buffer") -- }}}
	-- {{{ mini.trailspace
	require("mini.trailspace").setup()
	vim.api.nvim_create_user_command("Trim", MiniTrailspace.trim, { desc = "Trim trailing whitespace" }) -- }}}
	-- {{{ mini.diff
	require("mini.diff").setup({
		mappings = {
			apply = "<leader>ha",
			reset = "<leader>hr",
		},
	})
	nmap("<leader>ho", MiniDiff.toggle_overlay, "Hunks overlay") -- }}}
	-- {{{ mini.git
	require("mini.git").setup()
	nmap("<leader>hi", MiniGit.show_at_cursor, "Show line history") -- }}}
	-- {{{ mini.pick
	local pick = require("mini.pick")
	pick.setup({ source = { show = pick.default_show } })
	require("mini.extra").setup()
	vim.ui.select = MiniPick.ui_select

	local builtin = MiniPick.builtin
	local extra = MiniExtra.pickers
	nmap("<leader>/", function()
		return extra.buf_lines({ scope = "current" }, {})
	end, "Search buffer (fuzzy)")
	nmap("<leader><leader>", builtin.buffers, "Search open buffers")
	nmap("<leader>s.", builtin.resume, "Resume previous picker")
	nmap("<leader>s/", extra.buf_lines, "Search open buffers (fuzzy)")
	nmap("<leader>sf", builtin.files, "Search files")
	nmap("<leader>sg", builtin.grep_live, "Search by grep")
	nmap("<leader>sh", function()
		return builtin.help({ default_split = "vertical" })
	end, "Search help")
	nmap("<leader>sr", extra.oldfiles, "Search recent files") -- }}}
	-- {{{ mini.hipatterns
	require("mini.hipatterns").setup({
		highlighters = {
			hex_color = require("mini.hipatterns").gen_highlighter.hex_color(),
		},
	}) -- }}}
end)
