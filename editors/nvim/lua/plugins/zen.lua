local plugins = {
  {
    'folke/zen-mode.nvim',
    dependencies = {
      {
        'folke/twilight.nvim',
        cmd = { 'Twilight' },
        keys = { { '<leader>tw', '<cmd>Twilight<cr>', desc = 'Toggle twilight' } },
        config = true,
      },
    },
    cmd = { 'ZenMode' },
    keys = { { '<leader>tz', '<cmd>ZenMode<cr>', desc = 'Toggle zen-mode' } },
  },
}

return plugins
