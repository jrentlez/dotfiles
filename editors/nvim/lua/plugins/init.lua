local add, now, later = MiniDeps.add, MiniDeps.now, MiniDeps.later

-- allow plugins to extend lsp capabilites
_G.LspClientCapabilites = vim.lsp.protocol.make_client_capabilities()

require("plugins.mini")
require("plugins.treesitter")
require("plugins.cmp")
require("plugins.lsp")
require("plugins.navigator")
require("plugins.colorscheme")
require("plugins.liveserver")
