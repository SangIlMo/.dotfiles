return {
  -- 파일 트리
  { "nvim-tree/nvim-tree.lua", dependencies = { "nvim-tree/nvim-web-devicons" }, config = true },

  -- 테마
  { "folke/tokyonight.nvim", priority = 1000, config = function()
      vim.cmd("colorscheme tokyonight")
    end
  },

  -- LSP
  { "neovim/nvim-lspconfig" },
  { "williamboman/mason.nvim", build = ":MasonUpdate", config = true },
  { "williamboman/mason-lspconfig.nvim" },

  -- 자동완성
  { "hrsh7th/nvim-cmp" },
  { "hrsh7th/cmp-nvim-lsp" },
  { "L3MON4D3/LuaSnip" },
  { "saadparwaiz1/cmp_luasnip" },
  { "rafamadriz/friendly-snippets" },

  -- 상태바
  { "nvim-lualine/lualine.nvim", dependencies = { "nvim-tree/nvim-web-devicons" }, config = true },

  -- 문법 강조
  { "nvim-treesitter/nvim-treesitter", build = ":TSUpdate", config = true },

  -- 텔레스코프 (파일 탐색)
  { "nvim-telescope/telescope.nvim", dependencies = { "nvim-lua/plenary.nvim" }, config = true },
}
