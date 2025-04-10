---@module "mini.deps"

local add, now, later = MiniDeps.add, MiniDeps.now, MiniDeps.later

now(function()
	require("mini.notify").setup()
	vim.notify = MiniNotify.make_notify()

	require("mini.files").setup()

	vim.o.undofile = true
	-- Enable all filetype plugins
	vim.cmd("filetype plugin indent on")

	vim.api.nvim_create_autocmd("UIEnter", {
		desc = "UI modules from mini.nvim",
		group = vim.api.nvim_create_augroup("mini-ui-modules", { clear = true }),
		callback = function()
			vim.o.breakindent = true
			vim.o.conceallevel = 2
			vim.o.cursorline = true
			vim.o.formatoptions = "qjl1"
			vim.o.ignorecase = true
			vim.o.inccommand = "split"
			vim.o.incsearch = true
			vim.o.infercase = true
			vim.o.linebreak = true
			vim.o.list = true
			vim.o.listchars = "tab:> ,extends:…,precedes:…,nbsp:␣"
			vim.o.mouse = "a"
			vim.o.number = true
			vim.o.relativenumber = true
			vim.o.scrolloff = 10
			vim.o.smartcase = true
			vim.o.smartindent = true
			vim.o.splitbelow = true
			vim.o.splitright = true
			vim.o.timeoutlen = 300
			vim.o.updatetime = 250
			vim.o.virtualedit = "block"
			vim.o.wrap = false
			vim.o.wrap = false
			vim.opt.shortmess:append("cC")

			vim.keymap.set({ "n", "x" }, "j", [[v:count == 0 ? 'gj' : 'j']], { expr = true })
			vim.keymap.set({ "n", "x" }, "k", [[v:count == 0 ? 'gk' : 'k']], { expr = true })

			require("mini.icons").setup({
				style = vim.env.HAS_NERD_FONT and "glyph" or "ascii",
			})
			require("mini.icons").tweak_lsp_kind()
		end,
	})
end)

later(function()
	vim.o.clipboard = "unnamedplus"

	vim.cmd.colorscheme("default")

	vim.diagnostic.config({
		virtual_text = { source = "if_many" },
	})

	vim.api.nvim_create_autocmd("TextYankPost", {
		group = vim.api.nvim_create_augroup("hl_on_yank", { clear = true }),
		callback = function()
			vim.hl.on_yank()
		end,
		desc = "Highlight yanked text",
	})

	-- Keymaps -------------------------------------------------------------

	local function nmap(lhs, rhs, desc)
		vim.keymap.set("n", lhs, rhs, { desc = desc })
	end

	nmap("<leader>f", function()
		MiniFiles.open(vim.api.nvim_buf_get_name(0))
	end, "Open file explorer")

	nmap("<Esc>", "<cmd>nohlsearch<cr>", "Clear highlights on search when pressing <Esc> in normal mode (:h hlsearch)")

	nmap("<leader>q", vim.diagnostic.setloclist, "Open diagnostic loclist")

	nmap("<leader>e", function()
		vim.diagnostic.config({
			virtual_lines = { current_line = true },
			virtual_text = false,
		})
		local line = vim.api.nvim_win_get_cursor(0)[1]
		vim.api.nvim_create_autocmd("CursorMoved", {
			group = vim.api.nvim_create_augroup("line-diagnostics", { clear = true }),
			callback = function()
				local newline = vim.api.nvim_win_get_cursor(0)[1]
				if newline == line then
					return false
				end

				vim.diagnostic.config({ virtual_text = { source = "if_many" }, virtual_lines = false })
				return true
			end,
			desc = "Go back to the old config when leaving the line",
		})
	end, "Enable virtual lines")

	nmap("gb", "<cmd>bnext<cr>", "Go to next buffer")
	nmap("gB", "<cmd>bprevious<cr>", "Go to pevious buffer")

	vim.keymap.set("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })

	-- mini.bufremove ------------------------------------------------------

	require("mini.bufremove").setup()
	nmap("<leader>db", MiniBufremove.delete, "Delete buffer")

	-- mini.completion -----------------------------------------------------

	require("mini.snippets").setup()
	require("mini.completion").setup({ lsp_completion = { source_func = "omnifunc", auto_setup = false } })
	vim.o.completeopt = "menuone,fuzzy,noinsert"

	-- mini.ai -------------------------------------------------------------

	add({ source = "nvim-treesitter/nvim-treesitter-textobjects", checkout = "main", monitor = "main" })

	require("mini.ai").setup()
	local ts = MiniAi.gen_spec.treesitter
	local gen_ai_spec = require("mini.extra").gen_ai_spec
	require("mini.ai").setup({
		custom_textobjects = {
			F = ts({ a = "@function.outer", i = "@function.inner" }),
			o = ts({
				a = { "@conditional.outer", "@loop.outer" },
				i = { "@conditional.inner", "@loop.inner" },
			}),
			B = gen_ai_spec.buffer(),
			D = gen_ai_spec.diagnostic(),
			I = gen_ai_spec.indent(),
			L = gen_ai_spec.line(),
			N = gen_ai_spec.number(),
		},
	})

	-- mini.surround -------------------------------------------------------

	require("mini.surround").setup()

	-- mini.trailspace -----------------------------------------------------

	require("mini.trailspace").setup()
	vim.api.nvim_create_user_command("Trim", MiniTrailspace.trim, { desc = "Trim trailing whitespace" })

	-- mini.pairs ----------------------------------------------------------

	require("mini.pairs").setup()

	-- mini.indentscope ----------------------------------------------------

	require("mini.indentscope").setup()

	-- mini.diff -----------------------------------------------------------

	require("mini.diff").setup({
		mappings = {
			apply = "<leader>ha",
			reset = "<leader>hr",
		},
	})
	nmap("<leader>ho", MiniDiff.toggle_overlay, "Hunks overlay")

	-- mini.git -----------------------------------------------------------

	require("mini.git").setup()
	nmap("<leader>hi", MiniGit.show_at_cursor, "Show line history")

	-- mini.pick -----------------------------------------------------------

	require("mini.pick").setup()
	vim.ui.select = MiniPick.ui_select

	local bi, ex = MiniPick.builtin, require("mini.extra").pickers
	nmap("<leader>sh", function()
		return bi.help({ default_split = "vertical" })
	end, "Search help")
	nmap("<leader>sk", ex.keymaps, "Search keymaps")
	nmap("<leader>sf", bi.files, "Search files")
	nmap("<leader>sg", bi.grep_live, "Search by grep")
	nmap("<leader>sd", ex.diagnostic, "Search all diagnostics")
	nmap("<leader>sD", function()
		ex.diagnostic({ scope = "current" })
	end, "Search buffer diagnostics")
	nmap("<leader>sr", ex.oldfiles, "Search recent files")
	nmap("<leader>s.", bi.resume, "Resume previous picker")
	nmap("<leader>sb", bi.buffers, "Search open buffers")
	nmap("<leader>/", function()
		return ex.buf_lines({ scope = "current" }, {})
	end, "Search buffer (fuzzy)")
	nmap("<leader>sn", function()
		return bi.files({}, {
			source = {
				cwd = vim.fn.stdpath("config"),
				name = "Neovim config files",
			},
		})
	end, "Search neovim config")
	nmap("<leader>s/", ex.buf_lines, "Search open buffers (fuzzy)")
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
	end, "Search pickers")

	-- mini.hipatterns -----------------------------------------------------

	local hi = require("mini.hipatterns")
	local words = require("mini.extra").gen_highlighter.words
	hi.setup({
		highlighters = {
			fixme = words({ "FIXME", "BUG" }, "MiniHipatternsFixme"),
			hack = words({ "HACK", "WARN" }, "MiniHipatternsHack"),
			todo = words({ "TODO" }, "MiniHipatternsTodo"),
			note = words({ "NOTE", "INFO", "HINT" }, "MiniHipatternsNote"),
			hex_color = hi.gen_highlighter.hex_color(),
		},
	})

	-- mini.clue -----------------------------------------------------------

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
			{ mode = "n", keys = "<leader>s", desc = "+Search" },
			{ mode = "n", keys = "<leader>h", desc = "+Hunks" },
			{ mode = "v", keys = "<leader>h", desc = "+Hunks" },
			{ mode = "n", keys = "<leader>d", desc = "+Delete" },
		},

		window = {
			delay = vim.o.timeoutlen,
			config = {
				width = "auto",
			},
		},
	})
end)
