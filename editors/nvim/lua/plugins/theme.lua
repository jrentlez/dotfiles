local themes = {
  {
    {
      'catppuccin/nvim',
      name = 'catppuccin',
      priority = 1000,
      opts = {
        flavour = 'auto',
        color_overrides = {
          mocha = {
            base = '#000000',
            mantle = '#0f0f0f',
            crust = '#080808',
          },
        },
        integrations = {
          cmp = true,
          gitsigns = true,
          treesitter = true,
          mini = {
            enabled = true,
            indentscope_color = '',
          },
          mason = true,
          native_lsp = {
            enabled = true,
          },
          which_key = true,
          -- For more plugins integrations please scroll down (https://github.com/catppuccin/nvim#integrations)
        },
      },
      config = function(_, opts)
        require('catppuccin').setup(opts)
        vim.cmd.colorscheme 'catppuccin'
      end,
    },
  },
}

return themes
