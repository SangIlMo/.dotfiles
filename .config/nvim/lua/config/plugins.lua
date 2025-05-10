return {
	-- 파일 트리
	{
		"nvim-tree/nvim-tree.lua",
		dependencies = { "nvim-tree/nvim-web-devicons" },
		config = true,
	},

	-- 테마
	{
		"folke/tokyonight.nvim",
		priority = 1000,
		config = function()
			vim.cmd("colorscheme tokyonight")
		end,
	},

	-- LSP
	{ "neovim/nvim-lspconfig" },
	{
		"williamboman/mason.nvim",
		build = ":MasonUpdate",
		config = true,
	},
	{ "williamboman/mason-lspconfig.nvim" },

	-- 자동완성
	{ "hrsh7th/nvim-cmp" },
	{ "hrsh7th/cmp-nvim-lsp" },
	{ "L3MON4D3/LuaSnip" },
	{ "saadparwaiz1/cmp_luasnip" },
	{ "rafamadriz/friendly-snippets" },

	-- 포맷팅
	{
		"stevearc/conform.nvim",
		config = function()
			require("conform").setup({
				require("conform").setup({
					format_on_save = function(bufnr)
						local apply_ft = { lua = true, json = true, md = true, yaml = true, sh = true }
						local ft = vim.bo[bufnr].filetype
						if not apply_ft[ft] then
							return
						end
						return {
							lsp_fallback = true,
							timeout_ms = 1000,
						}
					end,
				}),
				formatters_by_ft = {
					-- 개인 설정파일 등 (기본 포맷터)
					lua = { "stylua" },
					markdown = { "prettier" },
					yaml = { "prettier" },
					json = { "prettier" },
					sh = { "shfmt" },
				},
			})
		end,
	},

	-- 상태바
	{
		"nvim-lualine/lualine.nvim",
		dependencies = { "nvim-tree/nvim-web-devicons" },
		config = function()
			require("lualine").setup({
				options = {
					theme = "auto",
					section_separators = "",
					component_separators = "",
				},
				sections = {
					lualine_a = { "mode" },
					lualine_b = { "branch" },
					lualine_c = { "filename" }, -- ✅ 파일명 표시
					lualine_x = { "encoding", "fileformat", "filetype" },
					lualine_y = { "progress" },
					lualine_z = { "location" },
				},
			})
		end,
	},

	-- 문법 강조
	{ "nvim-treesitter/nvim-treesitter", build = ":TSUpdate", config = true },

	-- 텔레스코프 (파일 탐색)
	{ "nvim-telescope/telescope.nvim", dependencies = { "nvim-lua/plenary.nvim" }, config = true },
}
