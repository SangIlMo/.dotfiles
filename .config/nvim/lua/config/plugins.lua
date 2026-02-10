return {
	-- 파일 트리
	{
		"nvim-tree/nvim-tree.lua",
		dependencies = { "nvim-tree/nvim-web-devicons" },
		config = true,
	},

	-- 테마 (Dracula)
	{
		"Mofiqul/dracula.nvim",
		priority = 1000,
		config = function()
			require("dracula").setup({ transparent_bg = true })
			vim.cmd("colorscheme dracula")
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
				-- 저장 시 포매팅
				format_on_save = function(bufnr)
					local apply_ft = {
						lua = true,
						json = true,
						markdown = true,
						yaml = true,
						sh = true,
					}
					local ft = vim.bo[bufnr].filetype
					if not apply_ft[ft] then
						return
					end
					return {
						lsp_fallback = true,
						timeout_ms = 1000,
					}
				end,
				-- 파일형식별 포매터 지정
				formatters_by_ft = {
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
					lualine_c = { { "filename", path = 1, file_status = true } }, -- ✅ 파일명 표시
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

	-- Copilot
	{
		"zbirenbaum/copilot.lua",
		event = "InsertEnter",
		config = function()
			require("copilot").setup({
				panel = { enabled = true, keymap = { open = "<Leader>cp" } },
				suggestion = {
					enabled = true,
					auto_trigger = true,
					keymap = {
						accept = "<C-l>",
						next = "<C-]>",
						prev = "<C-[>",
						dismiss = "<Esc>",
					},
				},
				filetypes = { ["*"] = true },
			})
		end,
	},
	{
		"zbirenbaum/copilot-cmp",
		dependencies = { "zbirenbaum/copilot.lua", "hrsh7th/nvim-cmp" },
		config = function()
			require("copilot_cmp").setup()
		end,
	},

	-- git

	{
		"lewis6991/gitsigns.nvim",
		dependencies = { "nvim-lua/plenary.nvim" },
		event = "BufReadPre", -- 파일 열 때 로드
		config = function()
			require("gitsigns").setup({
				-- 실시간 현재 줄 Blame 표시
				current_line_blame = true,
				current_line_blame_opts = {
					virt_text = true, -- virt-text로 표시
					virt_text_pos = "eol", -- 줄 끝에
					delay = 250, -- ms 단위 표시 지연
					ignore_whitespace = false,
				},
				current_line_blame_formatter = "<author>, <author_time:%Y-%m-%d> • [<abbrev_sha>] <summary>",
				-- 기본 설정 (선택)
				signs = {
					add = { text = "+" },
					change = { text = "~" },
					delete = { text = "_" },
					topdelete = { text = "‾" },
					changedelete = { text = "~" },
				},
				watch_gitdir = { interval = 1000 },
				attach_to_untracked = true,
			})

			-- Blame 토글 단축키 (<leader>gb)
			vim.keymap.set("n", "<leader>gb", function()
				require("gitsigns").toggle_current_line_blame()
			end, { desc = "Toggle Git Blame for current line" })
		end,
	},
}
