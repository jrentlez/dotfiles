local add, now, later = MiniDeps.add, MiniDeps.now, MiniDeps.later

now(function()
	require("mini.notify").setup()
	vim.notify = require("mini.notify").make_notify()
end)

now(function()
	require("mini.basics").setup({
		options = {
			extra_ui = true,
		},
	})

	-- [[ Additional options ]]
	-- Relative line numbers
	vim.opt.relativenumber = true
	-- Sync clipboard between OS and Neovim.
	-- Schedule the setting after `UiEnter` because it can increase startup-time.
	-- Remove this option if you want your OS clipboard to remain independent.
	-- See `:help 'clipboard'`
	vim.schedule(function()
		vim.opt.clipboard = "unnamedplus"
	end)
	-- Decrease update time
	vim.opt.updatetime = 250
	-- Decrease mapped sequence wait time
	-- Displays which-key popup sooner
	vim.opt.timeoutlen = 300
	-- Preview substitutions live, as you type!
	vim.opt.inccommand = "split"
	-- Minimal number of screen lines to keep above and below the cursor.
	vim.opt.scrolloff = 10
	-- Some themes depend on this
	vim.o.background = "dark"
	-- Wrap lines
	vim.opt.wrap = true
	-- Allow directory local config
	vim.opt.exrc = true

	-- [[ Additional keymaps ]]
	local nmap = function(lhs, rhs, desc)
		vim.keymap.set("n", lhs, rhs, { desc = desc })
	end
	-- Clear highlights on search when pressing <Esc> in normal mode
	--  See `:help hlsearch`
	nmap("<Esc>", "<cmd>nohlsearch<cr>")
	-- Diagnostic keymaps
	nmap("<leader>e", vim.diagnostic.open_float, "Show diagnostic [E]rror messages")
	nmap("<leader>q", vim.diagnostic.setloclist, "Open diagnostic [Q]uickfix list")
	-- Manage buffers
	nmap("gb", "<cmd>bnext<cr>", "Goto next buffer")
	nmap("gB", "<cmd>bprevious<cr>", "Goto previous buffer")
	-- Exit terminal mode in the builtin terminal
	vim.keymap.set("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })
end)

now(function()
	require("mini.statusline").setup({
		use_icons = vim.g.have_nerd_font,
	})
end)
now(function()
	require("mini.tabline").setup({
		show_icons = vim.g.have_nerd_font,
		format = function(buf_id, label)
			local suffix = vim.bo[buf_id].modified and "+" or ""
			return string.format("%d:%s%s", buf_id, MiniTabline.default_format(buf_id, label), suffix)
		end,
	})
end)
-- Hide when only one buffer is opened
vim.api.nvim_create_autocmd("BufEnter", {
	desc = "Hide tabline when only one buffer is opened",
	group = vim.api.nvim_create_augroup("mini-tabline-hide", { clear = true }),
	callback = vim.schedule_wrap(function()
		local n_listed_bufs = 0
		for _, buf_id in ipairs(vim.api.nvim_list_bufs()) do
			if vim.fn.buflisted(buf_id) == 1 then
				n_listed_bufs = n_listed_bufs + 1
			end
		end
		vim.o.showtabline = n_listed_bufs > 1 and 2 or 0
	end),
})
now(function()
	require("mini.extra").setup()
end)
now(function()
	require("mini.files").setup()
	vim.keymap.set("n", "<leader>f", function()
		MiniFiles.open(vim.api.nvim_buf_get_name(0))
	end, { desc = "Open [F]ile explorer" })
end)
now(function()
	require("mini.misc").setup()
	MiniMisc.setup_restore_cursor()
end)

later(function()
	require("mini.bufremove").setup()
	vim.keymap.set("n", "<leader>db", MiniBufremove.delete, { desc = "[D]elete current [B]uffer" })
end)
later(function()
	require("mini.ai").setup()
	add({ source = "nvim-treesitter/nvim-treesitter-textobjects", checkout = "main", monitor = "main" })
	local ts = require("mini.ai").gen_spec.treesitter
	require("mini.ai").setup({
		custom_textobjects = {
			F = ts({ a = "@function.outer", i = "@function.inner" }),
			o = ts({
				a = { "@conditional.outer", "@loop.outer" },
				i = { "@conditional.inner", "@loop.inner" },
			}),
		},
	})
end)
later(function()
	require("mini.surround").setup()
end)
later(function()
	require("mini.trailspace").setup()
	vim.api.nvim_create_user_command("MiniTrim", MiniTrailspace.trim, { desc = "Trim trailing whitespace" })
end)
later(function()
	require("mini.pairs").setup()
end)
later(function()
	require("mini.indentscope").setup()
end)
later(function()
	require("mini.diff").setup({
		mappings = {
			apply = "<leader>ha",
			reset = "<leader>hr",
		},
	})
	vim.keymap.set("n", "<leader>ho", MiniDiff.toggle_overlay, { desc = "Toggle [H]unk [O]verlay" })
end)
later(function()
	require("mini.git").setup()
	vim.keymap.set("n", "<leader>hi", MiniGit.show_at_cursor, { desc = "Show line history" })
end)
later(function()
	require("mini.pick").setup()
	vim.ui.select = MiniPick.ui_select
	local nmap = function(lhs, rhs, desc)
		vim.keymap.set("n", lhs, rhs, { desc = desc })
	end
	local bi, ex = MiniPick.builtin, MiniExtra.pickers
	nmap("<leader>sh", bi.help, "[S]earch [H]elp")
	nmap("<leader>sk", ex.keymaps, "[S]earch [K]eymaps")
	nmap("<leader>sf", bi.files, "[S]earch [F]iles")
	nmap("<leader>sg", bi.grep_live, "[S]earch by [G]rep")
	nmap("<leader>sd", ex.diagnostic, "[S]earch [D]iagnostics")
	nmap("<leader>sr", bi.resume, "[S]earch [R]esume")
	nmap("<leader>s.", ex.oldfiles, '[S]earch recent files ("." for repeat)')
	nmap("<leader><leader>", bi.buffers, "[S]earch [B]uffers")
	nmap("<leader>/", function()
		return ex.buf_lines({ scope = "current" }, {})
	end, "[/] Fuzzily search in the current buffer")
	nmap("<leader>sn", function()
		return bi.files({}, {
			source = {
				cwd = vim.fn.stdpath("config"),
				name = "Neovim config files",
			},
		})
	end, "[S]earch [N]eovim config files")
	nmap("<leader>s/", ex.buf_lines, "[S]earch [/] fuzzily in buffers ")
	nmap("<leader>sp", function()
		local all = vim.tbl_extend("error", bi, ex)
		MiniPick.start({
			source = {
				items = vim.tbl_keys(all),
				name = "Pickers",
				choose = function(picker)
					all[picker]()
				end,
			},
		})
	end, "[S]earch [P]ickers")
end)

-- Highlight hex colors
later(function()
	local hi = require("mini.hipatterns")
	hi.setup({
		highlighters = {
			fixme = { pattern = { "%f[%w]()FIXME()%f[%W]", "%f[%w]()BUG()%f[%W]" }, group = "MiniHipatternsFixme" },
			hack = { pattern = "%f[%w]()HACK()%f[%W]", group = "MiniHipatternsHack" },
			todo = { pattern = "%f[%w]()TODO()%f[%W]", group = "MiniHipatternsTodo" },
			note = {
				pattern = { "%f[%w]()NOTE()%f[%W]", "%f[%w]()INFO()%f[%W]", "%f[%w]()HINT()%f[%W]" },
				group = "MiniHipatternsNote",
			},
			hex_color = hi.gen_highlighter.hex_color(),
		},
	})
end)

later(function()
	local miniclue = require("mini.clue")
	miniclue.setup({
		triggers = {
			-- Leader triggers
			{ mode = "n", keys = "<Leader>" },
			{ mode = "x", keys = "<Leader>" },

			-- Built-in completion
			{ mode = "i", keys = "<C-x>" },

			-- `g` key
			{ mode = "n", keys = "g" },
			{ mode = "x", keys = "g" },

			-- Marks
			{ mode = "n", keys = "'" },
			{ mode = "n", keys = "`" },
			{ mode = "x", keys = "'" },
			{ mode = "x", keys = "`" },

			-- Registers
			{ mode = "n", keys = '"' },
			{ mode = "x", keys = '"' },
			{ mode = "i", keys = "<C-r>" },
			{ mode = "c", keys = "<C-r>" },

			-- Window commands
			{ mode = "n", keys = "<C-w>" },

			-- `z` key
			{ mode = "n", keys = "z" },
			{ mode = "x", keys = "z" },
		},

		clues = {
			miniclue.gen_clues.builtin_completion(),
			miniclue.gen_clues.g(),
			miniclue.gen_clues.marks(),
			miniclue.gen_clues.registers(),
			miniclue.gen_clues.windows(),
			miniclue.gen_clues.z(),
			-- Enhance this by adding descriptions for <Leader> mapping groups
			{ mode = "n", keys = "<leader>s", desc = "+[S]earch" },
			{ mode = "n", keys = "<leader>h", desc = "+Git [H]unk" },
			{ mode = "v", keys = "<leader>h", desc = "+Git [H]unk" },
			{ mode = "n", keys = "<leader>r", desc = "+[R]..." },
			{ mode = "n", keys = "<leader>c", desc = "+[C]ode ..." },
			{ mode = "n", keys = "<leader>d", desc = "+[D]elete" },
			{ mode = "n", keys = "<leader>t", desc = "+[T]oggle" },
		},

		window = {
			delay = vim.o.timeoutlen,
			config = {
				width = "auto",
			},
		},
	})
end)
later(function()
	local style = vim.g.have_nerd_font and "glyph" or "ascii"
	require("mini.icons").setup({
		style = style,
	})
	require("mini.icons").tweak_lsp_kind()

	local file_kind = 17
	MiniIcons.compat = {
		blink = {
			---@param ctx blink.cmp.DrawItemContext The item context
			---@return string icon, string hl The icon text and highlight group
			kind_icon_text_and_hl = function(ctx)
				local icon, hl = MiniIcons.get("lsp", ctx.kind) or ctx.kind_icon, "BlinkCmpKind" .. ctx.kind
				if ctx.source_name == "Path" then
					if ctx.item.kind == file_kind then
						icon, hl = MiniIcons.get("file", ctx.item.label) or icon, hl
					else
						icon, hl = MiniIcons.get("directory", ctx.item.label) or icon, hl
					end
				end

				return icon .. ctx.icon_gap, hl
			end,
		},
	}
end)
