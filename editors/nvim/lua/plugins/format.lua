return {
  { -- Autoformat
    'stevearc/conform.nvim',
    dependencies = {
      'neovim/nvim-lspconfig',
      { 'williamboman/mason.nvim', config = true },
      'frostplexx/mason-bridge.nvim',
    },
    opts = {
      format_on_save = {
        timeout_ms = 500,
        lsp_fallback = true,
      },
    },
    config = function(_, opts)
      require('mason-bridge').setup()
      if not opts.formatters_by_ft then
        opts.formatters_by_ft = require('mason-bridge').get_formatters()
      else
        vim.notify('/lua/plugins/format.lua: formatters_by_ft is already set: ' .. vim.inspect(opts.formatters_by_ft), vim.log.levels.ERROR, {})
      end
      require('conform').setup(opts)
    end,
  },
}
