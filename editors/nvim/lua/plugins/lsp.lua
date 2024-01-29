return { -- LSP Configuration & Plugins
  'neovim/nvim-lspconfig',
  dependencies = {
    'williamboman/mason.nvim',
    'williamboman/mason-lspconfig.nvim',
    'WhoIsSethDaniel/mason-tool-installer.nvim',
    'mini.nvim',

    -- `neodev` configures Lua LSP for your Neovim config, runtime and plugins
    -- used for completion, annotations and signatures of Neovim apis
    { 'folke/neodev.nvim', opts = {} },
  },
  config = function()
    vim.api.nvim_create_autocmd('LspAttach', {
      group = vim.api.nvim_create_augroup('kickstart-lsp-attach', { clear = true }),
      callback = function(event)
        -- Add lsp keymaps
        local keymaps = require 'keymaps'
        keymaps.add(keymaps.lsp)

        local client = vim.lsp.get_client_by_id(event.data.client_id)

        -- The following two autocommands are used to highlight references of the
        -- word under your cursor when your cursor rests there for a little while.
        --    See `:help CursorHold` for information about when this is executed
        if client and client.supports_method(vim.lsp.protocol.Methods.textDocument_documentHighlight) then
          local highlight_augroup = vim.api.nvim_create_augroup('kickstart-lsp-highlight', { clear = false })
          vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
            buffer = event.buf,
            group = highlight_augroup,
            callback = vim.lsp.buf.document_highlight,
          })

          vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
            buffer = event.buf,
            group = highlight_augroup,
            callback = vim.lsp.buf.clear_references,
          })

          vim.api.nvim_create_autocmd('LspDetach', {
            group = vim.api.nvim_create_augroup('kickstart-lsp-detach', { clear = true }),
            callback = function(event2)
              vim.lsp.buf.clear_references()
              vim.api.nvim_clear_autocmds { group = 'kickstart-lsp-highlight', buffer = event2.buf }
            end,
          })
        end

        -- Enable inlay hints
        if client and client.supports_method(vim.lsp.protocol.Methods.textDocument_inlayHint) then
          vim.lsp.inlay_hint.enable(true, { bufnr = event.buf })
        end
      end,
    })

    --  Add any additional override configuration in the following tables. Available keys are:
    --  - cmd (table): Override the default command used to start the server
    --  - filetypes (table): Override the default list of associated filetypes for the server
    --  - capabilities (table): Override fields in capabilities. Can be used to disable certain LSP features.
    --  - settings (table): Override the default settings passed when initializing the server.
    --        For example, to see the options for `lua_ls`, you could go to: https://luals.github.io/wiki/settings/
    local servers = {
      -- LSP for Rust is installed via rustup and setup in plugins_d/rust.lua,

      tsserver = {
        settings = {
          typescript = {
            inlayHints = {
              includeInlayEnumMemberValueHints = 'all',
              includeInlayFunctionLikeReturnTypeHints = true,
              includeInlayFunctionParameterTypeHints = true,
              includeInlayPropertyDeclarationTypeHints = true,
              includeInlayVariableTypeHints = true,
            },
          },
        },
      },

      typst_lsp = {
        settings = {
          exportPdf = 'onType',
          experimentalFormatMode = 'on',
        },
      },

      bashls = {},

      texlab = {
        settings = {
          texlab = {
            build = {
              onSave = true,
              forwardSearchAfter = true,
            },
            forwardSearch = {
              executable = 'zathura',
              args = {
                '--synctex-forward',
                '%l:1:%f',
                '%p',
              },
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

      eslint = {},

      lua_ls = {},

      lemminx = {},
    }

    -- You can add other tools here that you want Mason to install
    -- for you, so that they are available from within Neovim.
    local tools = vim.tbl_keys(servers or {})
    vim.list_extend(tools, {
      'stylua',
      'prettierd',
      'typstfmt',
    })
    require('mason-tool-installer').setup { ensure_installed = tools, auto_update = true }

    require('mason-lspconfig').setup_handlers {
      function(server_name)
        local server = servers[server_name] or {}
        -- This handles overriding only values explicitly passed
        -- by the server configuration above. Useful when disabling
        -- certain features of an LSP (for example, turning off formatting for tsserver)
        server.capabilities = vim.tbl_deep_extend('force', {}, require('common').capabilities, server.capabilities or {})
        require('lspconfig')[server_name].setup(server)
      end,
    }
  end,
}
