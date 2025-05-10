local keymap = vim.keymap.set

keymap("n", "<leader>w", ":w<CR>")
keymap("n", "<leader>q", ":q<CR>")
keymap("n", "<leader>e", ":NvimTreeToggle<CR>")

-- Telescope 키맵 추가

local layout_opts = {
    layout_strategy = "vertical",
    layout_config = {
        prompt_position = "top",
        preview_cutoff = 1,
        height = 0.8,
    },
}

keymap("n", "<leader>ff", function()
    require("telescope.builtin").find_files(layout_opts)
end, { desc = "Telescope: Find Files with bottom preview" })

keymap("n", "<leader>fg", function()
    require("telescope.builtin").live_grep(layout_opts)
end, { desc = "Telescope: Live Grep with bottom preview" })

keymap("n", "<leader>fb", function()
    require("telescope.builtin").buffers(layout_opts)
end, { desc = "Telescope: Buffers with bottom preview" })

keymap("n", "<leader>e", function()
    local view = require("nvim-tree.view")
    local api = require("nvim-tree.api")

    if view.is_visible() then
        api.tree.focus()
    else
        api.tree.open()
    end
end, { desc = "Toggle or focus NvimTree" })
keymap("n", "<leader>fd", function()
    require("telescope.builtin").lsp_definitions()
end, { desc = "Telescope: Go to Definition" })
