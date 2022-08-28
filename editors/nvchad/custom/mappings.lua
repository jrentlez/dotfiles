local M = {}


M.rust = {
  plugin = true,
  n = {
    ["K"] = {
      function ()
        require("rust-tools").hover_actions.hover_actions()
      end,
      "Rust hover"
    },
  }
}

M.telescope = {
  plugin = true,

  n = {
    ["<leader>fd"] = { "<cmd> Telescope diagnostics <CR>", "Find diagnostics" },
  },
}

M.markdown = {
  plugin = true,

  n = {
    ["<leader>md"] = {"<cmd> MarkdownPreviewToggle <CR>", "Toggle markdown preview"}
  }
}

return M
