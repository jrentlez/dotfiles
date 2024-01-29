return { -- Collection of various small independent plugins/modules
  'echasnovski/mini.nvim',
  dependencies = {
    { 'nvim-tree/nvim-web-devicons', enabled = vim.g.have_nerd_font },
  },
  config = function()
    -- Better Around/Inside textobjects
    --
    -- Examples:
    --  - va)  - [V]isually select [A]round [)]paren
    --  - yinq - [Y]ank [I]nside [N]ext [']quote
    --  - ci'  - [C]hange [I]nside [']quote
    require('mini.ai').setup { n_lines = 500 }

    -- Add/delete/replace surroundings (brackets, quotes, etc.)
    --
    -- - saiw) - [S]urround [A]dd [I]nner [W]ord [)]Paren
    -- - sd'   - [S]urround [D]elete [']quotes
    -- - sr)'  - [S]urround [R]eplace [)] [']
    require('mini.surround').setup()

    -- Simple and easy statusline.
    --  You could remove this setup call if you don't like it,
    --  and try some other statusline plugin
    local statusline = require 'mini.statusline'
    -- set use_icons to true if you have a Nerd Font
    statusline.setup { use_icons = vim.g.have_nerd_font }

    -- Which buffer to show in window(s) after its current buffer is removed
    require('mini.bufremove').setup()

    -- Show and remove trailing space
    require('mini.trailspace').setup()

    -- Minimal and fast autopairs
    require('mini.pairs').setup()

    -- Visualize and work with indentscope
    require('mini.indentscope').setup()

    -- Minimal and fast tabline
    require('mini.tabline').setup {
      show_icons = vim.g.have_nerd_font,
    }

    -- Highlight hex colors
    local hi = require 'mini.hipatterns'
    hi.setup {
      highlighters = {
        hex_color = hi.gen_highlighter.hex_color(),
      },
    }

    -- Hide when only one buffer is opened
    vim.api.nvim_create_autocmd('BufEnter', {
      desc = 'Hide tabline when only one buffer is opened',
      group = vim.api.nvim_create_augroup('mini-tabline-hide', { clear = true }),
      callback = vim.schedule_wrap(function()
        local n_listed_bufs = 0
        for _, buf_id in ipairs(vim.api.nvim_list_bufs()) do
          if vim.fn.buflisted(buf_id) == 1 then
            n_listed_bufs = n_listed_bufs + 1
          end
        end
        vim.o.showtabline = n_listed_bufs > 1 and 2 or 0
      end),
    })

    -- file explorer
    require('mini.files').setup()

    -- Show notifications
    require('mini.notify').setup()
    vim.notify = require('mini.notify').make_notify()

    -- Telescope replacement
    require('mini.pick').setup()
    -- NOTE: Uncommment the next line to use `mini.pick` for default selection
    vim.ui.select = MiniPick.ui_select
    require('mini.extra').setup()

    -- gitsigns replacement
    require('mini.diff').setup()
    require('mini.git').setup()

    local keymaps = require 'keymaps'
    keymaps.add(keymaps.mini)
  end,
}
