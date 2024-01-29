local plugins = {
  {
    'jvalue/jayvee.nvim',
    dependencies = {
      'neovim/nvim-lspconfig',
      {
        'icedman/nvim-textmate',
        opts = {
          quick_load = true,
          extension_paths = { '~/.vscode-oss/extensions/' },
        },
      },
    },
    main = 'jayvee',
    init = function(_)
      vim.filetype.add { extension = { jv = 'jayvee' } }
    end,
    ft = 'jayvee',
    opts = {
      capabilities = require('common').capabilities,
    },
  },
}

return plugins
