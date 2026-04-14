-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- Escape shortcut
vim.keymap.set("i", "jj", "<Esc>", { desc = "Escape insert mode" })

-- Save / quit
vim.keymap.set("n", "<leader>wf", ":w!<CR>", { desc = "Force save" })
vim.keymap.set("n", "<leader>q", ":q<CR>", { desc = "Quit" })
vim.keymap.set("n", "<leader>wq", ":wq<CR>", { desc = "Save and quit" })

-- Window navigation
vim.keymap.set("n", "<leader>h", ":wincmd h<CR>", { desc = "Move to left window" })
vim.keymap.set("n", "<leader>j", ":wincmd j<CR>", { desc = "Move to window below" })
vim.keymap.set("n", "<leader>k", ":wincmd k<CR>", { desc = "Move to window above" })
vim.keymap.set("n", "<leader>l", ":wincmd l<CR>", { desc = "Move to right window" })

-- Buffer navigation
vim.keymap.set("n", "<C-n>", ":bnext<CR>", { desc = "Next buffer" })
vim.keymap.set("n", "<C-p>", ":bprev<CR>", { desc = "Previous buffer" })
