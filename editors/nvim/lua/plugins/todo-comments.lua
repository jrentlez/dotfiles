return {
  { -- Highlight todo, notes, etc in comments
    'folke/todo-comments.nvim',
    event = 'VimEnter',
    dependencies = { 'nvim-lua/plenary.nvim' },
    opts = {
      keywords = {
        FIX = {
          icon = 'b', -- icon used for the sign, and in search results
          color = 'error', -- can be a hex color, or a named color (see below)
          alt = { 'FIXME', 'BUG', 'FIXIT', 'ISSUE' }, -- a set of other keywords that all map to this FIX keywords
          -- signs = false, -- configure signs for some keywords individually
        },
        TODO = { icon = 'td', color = 'info' },
        HACK = { icon = 'h', color = 'warning' },
        WARN = { icon = 'w', color = 'warning', alt = { 'WARNING', 'XXX' } },
        PERF = { icon = 'p', alt = { 'OPTIM', 'PERFORMANCE', 'OPTIMIZE' } },
        NOTE = { icon = 'i', color = 'hint', alt = { 'INFO' } },
        TEST = { icon = 't', color = 'test', alt = { 'TESTING', 'PASSED', 'FAILED' } },
      },
    },
  },
}
