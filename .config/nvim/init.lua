require("config.options")
require("config.keymaps")

-- lazy.nvim 로드
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
vim.opt.rtp:prepend(lazypath)
require("lazy").setup(require("config.plugins"))

require("config.cmp")
require("config.lsp")

local project_config = vim.fn.findfile(".nvimrc", vim.fn.getcwd() .. ";")
if project_config ~= "" then
	vim.cmd("source " .. project_config)
end

vim.g.python3_host_prog = "/Users/sangilmo.fsl/.local/share/mise/installs/python/3.13.3/bin/python3"
