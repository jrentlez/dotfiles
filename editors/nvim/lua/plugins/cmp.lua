local add, now, later = MiniDeps.add, MiniDeps.now, MiniDeps.later

local function build_blink(params)
	vim.notify("Building blink.cmp", vim.log.levels.INFO)
	vim.system({ "cargo", "build", "--release" }, { cwd = params.path }, function(obj)
		if obj.code == 0 then
			vim.notify("Building blink.cmp done", vim.log.levels.INFO)
		else
			vim.notify("Building blink.cmp failed", vim.log.levels.ERROR)
		end
	end)
end

now(function()
	add({
		source = "saghen/blink.cmp",
		hooks = {
			post_install = build_blink,
			post_checkout = build_blink,
		},
	})

	---@module 'blink.cmp'
	---@type blink.cmp.Config
	local opts = {
		keymap = {
			preset = "default",
			["<Tab>"] = {},
			["<S-Tab>"] = {},
			["<C-l>"] = { "snippet_forward", "fallback" },
			["<C-h>"] = { "snippet_backward", "fallback" },
		},
		sources = {
			default = { "lsp", "path", "snippets" },
			per_filetype = {
				lua = { "lazydev", "lsp", "path", "snippets" },
			},
			providers = {
				lazydev = { name = "LazyDev", module = "lazydev.integrations.blink", score_offset = 100 },
				snippets = {
					opts = {
						friendly_snippets = false,
					},
				},
			},
		},
		signature = {
			enabled = true,
		},
		completion = {
			menu = {
				draw = {
					components = {
						kind_icon = {
							ellipsis = false,
							text = function(ctx)
								return select(1, MiniIcons.compat.blink.kind_icon_text_and_hl(ctx))
							end,
							highlight = function(ctx)
								return select(2, MiniIcons.compat.blink.kind_icon_text_and_hl(ctx))
							end,
						},
					},
				},
			},
		},
		appearance = {
			use_nvim_cmp_as_default = false,
			nerd_font_variant = "normal",
		},
	}
	require("blink.cmp").setup(opts)
	_G.LspClientCapabilites =
		vim.tbl_deep_extend("force", _G.LspClientCapabilites, require("blink.cmp").get_lsp_capabilities())
end)
