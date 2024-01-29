local plugins = {
  {
    'numToStr/Navigator.nvim',
    keys = {
      { '<C-h>', '<cmd>NavigatorLeft<cr>', { desc = 'Move focus to the left window' } },
      { '<C-l>', '<cmd>NavigatorRight<cr>', { desc = 'Move focus to the right window' } },
      { '<C-j>', '<cmd>NavigatorDown<cr>', { desc = 'Move focus to the lower window' } },
      { '<C-k>', '<cmd>NavigatorUp<cr>', { desc = 'Move focus to the upper window' } },
    },
    config = true,
  },
}

return plugins
