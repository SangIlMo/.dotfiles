-- lua/config/lsp.lua
require("mason").setup()
require("mason-lspconfig").setup({
	ensure_installed = { "lua_ls", "ts_ls", "pyright" },
})

local lspconfig = require("lspconfig")
local capabilities = require("cmp_nvim_lsp").default_capabilities()

lspconfig.lua_ls.setup({ capabilities = capabilities })
lspconfig.ts_ls.setup({
	capabilities = capabilities,
	root_dir = function()
		return vim.fn.getcwd() -- 👈 현재 nvim 작업 디렉토리를 root로 고정
	end,
})
lspconfig.pyright.setup({ capabilities = capabilities })
