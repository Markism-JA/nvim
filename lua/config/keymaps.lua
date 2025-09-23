-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
vim.keymap.set("n", "<C-d>", "<C-d>zz", { desc = "Scroll down and center" })
vim.keymap.set("n", "<C-u>", "<C-u>zz", { desc = "Scroll up and center" })

-- Normal mode: 'vv' enters Visual Block Mode (as if you pressed Ctrl+V)
vim.keymap.set("n", "vv", "<C-v>", { noremap = true, desc = "Visual Block Mode (vv)" })

-- Terminal mode mapping: Ctrl-\ Ctrl-n = Escape
vim.api.nvim_set_keymap("t", "<Leader><Esc>", "<C-\\><C-n>", { noremap = true, silent = true })
