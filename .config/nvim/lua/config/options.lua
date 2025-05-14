vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true
vim.opt.smartindent = true
vim.opt.wrap = false
vim.opt.scrolloff = 8
vim.opt.termguicolors = true
vim.opt.clipboard = "unnamedplus"
vim.opt.mouse = "a"
vim.opt.cursorline = true
vim.opt.splitbelow = true
vim.opt.splitright = true
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.g.mapleader = " "

-- 화면 너비 넘어가면 자동 줄 바꿈
vim.opt.wrap = true -- 화면 너비에서 줄 바꿈
vim.opt.linebreak = true -- 단어 단위로 잘라 넘김
vim.opt.breakindent = true -- 넘긴 줄 앞 들여쓰기 유지
vim.opt.showbreak = "↳ " -- 넘긴 줄 앞에 표시할 문자열 (선택)

-- 토글 매핑 (wrap on/off)
vim.keymap.set("n", "<leader>tw", function()
	vim.opt.wrap = not vim.opt.wrap:get()
	print("wrap:", vim.opt.wrap:get() and "on" or "off")
end, { desc = "Toggle wrap" })

-- setting auto read
vim.opt.autoread = true
vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter", "CursorHold" }, {
	pattern = "*",
	command = "checktime",
})
