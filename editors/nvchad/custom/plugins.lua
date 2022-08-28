local cu = require("core.utils")

local plugins = {
  {
    "ntpeters/vim-better-whitespace",
    event = "InsertEnter"
  },
  {
    "jose-elias-alvarez/null-ls.nvim",
    ft = {"python"},
    opts = function()
      return require("custom.configs.null-ls")
    end,
  },
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      "williamboman/mason.nvim",
      "williamboman/mason-lspconfig.nvim",
    },
    config = function ()
      require("plugins.configs.lspconfig")
      require("custom.configs.lspconfig")
    end,
  },
  {
    "rust-lang/rust.vim",
    ft = "rust",
    init = function ()
      vim.g.rustfmt_autosave = 1
    end,
  },
  {
    "simrat39/rust-tools.nvim",
    ft = "rust",
    dependencies = {
      "neovim/nvim-lspconfig",
      "nvim-lua/plenary.nvim"
    },
    opts = function ()
      return require("custom.configs.rust-tools")
    end,
    config = function (_, opts)
      require("rust-tools").setup(opts)
      cu.load_mappings("rust")
    end
  },
  {
    "NvChad/nvterm",
    enabled = false
  },
  {
    "ziglang/zig.vim",
    ft={"zig"},
  },
  {
    "iamcco/markdown-preview.nvim",
    ft = { "markdown" },
    build = function() vim.fn["mkdp#util#install"]() end,
    config = function (_, opts)
      cu.load_mappings("markdown")
    end
  },
  {
    "folke/twilight.nvim",
    opts = {
    -- your configuration comes here
    -- or leave it empty to use the default settings
    }
  },
  {
    "folke/zen-mode.nvim",
    cmd = {"ZenMode"},
    keys = {
      { "<leader>tz", "<cmd>ZenMode<CR>", "Toggle zen-mode"}
    },
    dependencies = {
      "folke/twilight.nvim"
    },
    opts = {
      -- your configuration comes here
      -- or leave it empty to use the default settings
    }
  }
}
return plugins
