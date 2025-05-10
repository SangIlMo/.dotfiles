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
    root_dir = require("lspconfig.util").root_pattern("package.json", "tsconfig.json", ".git"),
})
lspconfig.pyright.setup({ capabilities = capabilities })
