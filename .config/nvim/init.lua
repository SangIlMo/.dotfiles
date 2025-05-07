require("config.options")
require("config.keymaps")

-- lazy.nvim 로드
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
vim.opt.rtp:prepend(lazypath)
require("lazy").setup(require("config.plugins"))

require("config.cmp")
require("config.lsp")
