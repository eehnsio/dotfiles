-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- Better diagnostic navigation for Swedish keyboard
vim.keymap.set("n", "<leader>j", vim.diagnostic.goto_next, { desc = "Next diagnostic" })
vim.keymap.set("n", "<leader>k", vim.diagnostic.goto_prev, { desc = "Previous diagnostic" })

-- Alternative: use Ctrl for navigation
vim.keymap.set("n", "<C-n>", vim.diagnostic.goto_next, { desc = "Next diagnostic" })
vim.keymap.set("n", "<C-p>", vim.diagnostic.goto_prev, { desc = "Previous diagnostic" })

-- Harpoon keymaps
local harpoon = require("harpoon")

vim.keymap.set("n", "<leader>a", function()
	harpoon:list():add()
end, { desc = "Add to Harpoon" })

vim.keymap.set("n", "<leader>h", function()
	harpoon.ui:toggle_quick_menu(harpoon:list())
end, { desc = "Open harpoon menu" })

-- Disable LazyVim's default <leader>1-4 keybinds for buffers
pcall(vim.keymap.del, "n", "<leader>1")
pcall(vim.keymap.del, "n", "<leader>2")
pcall(vim.keymap.del, "n", "<leader>3")
pcall(vim.keymap.del, "n", "<leader>4")

-- Harpoon quick select
vim.keymap.set("n", "<leader>1", function()
	harpoon:list():select(1)
end, { desc = "Harpoon file 1" })

vim.keymap.set("n", "<leader>2", function()
	harpoon:list():select(2)
end, { desc = "Harpoon file 2" })

vim.keymap.set("n", "<leader>3", function()
	harpoon:list():select(3)
end, { desc = "Harpoon file 3" })

vim.keymap.set("n", "<leader>4", function()
	harpoon:list():select(4)
end, { desc = "Harpoon file 4" })

-- Harpoon navigation
vim.keymap.set("n", "<C-q>", function()
	harpoon:list():prev()
end, { desc = "Harpoon prev" })

vim.keymap.set("n", "<C-e>", function()
	harpoon:list():next()
end, { desc = "Harpoon next" })
