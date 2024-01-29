local plugins = {
  {
    'numToStr/FTerm.nvim',
    keys = {
      {
        '<leader>tt',
        function()
          require('FTerm').toggle()
        end,
        desc = 'Toggle floating terminal',
      },
    },
    config = true,
  },
}

return plugins
