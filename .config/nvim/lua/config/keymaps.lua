local keymap = vim.keymap.set

keymap("n", "<leader>w", ":w<CR>")
keymap("n", "<leader>q", ":q<CR>")
keymap("n", "<leader>e", ":NvimTreeToggle<CR>")

-- Telescope 키맵 추가 
keymap("n", "<leader>ff", ":Telescope find_files<CR>")
keymap("n", "<leader>fg", ":Telescope live_grep<CR>")
keymap("n", "<leader>fb", ":Telescope buffers<CR>")
keymap("n", "<leader>e", function()
  local view = require("nvim-tree.view")
  local api = require("nvim-tree.api")

  if view.is_visible() then
    api.tree.focus()
  else
    api.tree.open()
  end
end, { desc = "Toggle or focus NvimTree" })
