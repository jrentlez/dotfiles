local lspconf = require("plugins.configs.lspconfig")
local on_attach = lspconf.on_attach
local capabilities = lspconf.capabilities

local options = {
  server = {
    on_attach = on_attach,
    capabilities = capabilities,
    settings = {
      ["rust-analyzer"] = {
        check = {command = "clippy"}
      }
    }
  },
}

return options
