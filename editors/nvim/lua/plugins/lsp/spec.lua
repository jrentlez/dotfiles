local M = {}

M.servers = {
	mason = {
		vtsls = {
			settings = {
				typescript = {
					inlayHints = {
						parameterNames = { enabled = "literals" },
						parameterTypes = { enabled = true },
						variableTypes = { enabled = true },
						propertyDeclarationTypes = { enabled = true },
						functionLikeReturnTypes = { enabled = true },
						enumMemberValues = { enabled = true },
					},
				},
			},
			experimental = {
				completion = {
					enableServerSideFuzzyMatch = true,
				},
			},
		},
		tinymist = {
			settings = {
				exportPdf = "onSave",
				outputPath = "$root/$name",
				formatterMode = "typstyle",
			},
		},
		bashls = {},
		texlab = {
			settings = {
				texlab = {
					build = {
						args = { "-interaction=nonstopmode" },
					},
				},
			},
		},
		ruff = {},
		basedpyright = {},
		yamlls = {
			settings = {
				yaml = {
					format = {
						enable = true,
					},
				},
			},
		},
		jsonls = {},
		lua_ls = {},
		lemminx = {},
		vimls = {},
		biome = {},
		rust_analyzer = {
			settings = {
				["rust-analyzer"] = {
					check = {
						command = "clippy",
					},
					diagnostics = {
						experimental = {
							enable = true,
						},
					},
				},
			},
		},
		["eslint-lsp"] = {},
		clangd = {},
	},
	no_mason = {
		nushell = {},
	},
}

function M.custom_server_setup()
	-- jayvee has its own plugin independent of lspconfig and mason
	require("jayvee").setup({
		cmd = { "jayvee-language-server@nightly", "--stdio" },
		capabilities = _G.LspClientCapabilites,
	})
end

M.others = {
	"stylua",
	"shellcheck",
	"latexindent",
	"checkmake",
	"prettierd",
	"cpplint",
}

M.tools = function(self)
	return vim.list_extend(vim.tbl_keys(self.servers.mason), self.others)
end

M.formatters_by_ft = {
	lua = { "stylua" },
	typescript = function(bufnr)
		if string.find(vim.api.nvim_buf_get_name(bufnr), "jayvee") then
			return { "eslint_d" }
		else
			return { "biome-check" }
		end
	end,
	typescriptreact = { "biome-check" },
	javascript = function(bufnr)
		if string.find(vim.api.nvim_buf_get_name(bufnr), "jayvee") then
			return { "eslint_d" }
		else
			return { "biome-check" }
		end
	end,
	javascriptreact = { "biome-check" },
	json = { "biome-check" },
	jsonc = { "biome-check" },
	astro = { "biome-check" },
	svelte = { "biome-check" },
	vue = { "biome-check" },
	css = { "biome-check" },
}

M.linters_by_ft = {
	cpp = { "cpplint" },
}

return M
