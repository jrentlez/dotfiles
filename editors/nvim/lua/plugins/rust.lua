vim.g.rustaceanvim = {
  server = {
    default_settings = {
      capabilites = require('common').capabilities,
    },
  },
}

local plugins = {
  {
    'mrcjkb/rustaceanvim',
  },
}

return plugins
