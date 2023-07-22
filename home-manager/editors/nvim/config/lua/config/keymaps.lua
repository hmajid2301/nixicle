-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
--
local Util = require("lazyvim.util")

-- Paste
vim.keymap.set("x", "<leader>p", '"_dP', { desc = "Paste without updating register" })

-- Copy
vim.keymap.set("v", "<", "<gv", { desc = "Stay in visual mode during outdent" })
vim.keymap.set("v", ">", ">gv", { desc = "Stay in visual mode during indent" })

-- Buffers
vim.keymap.set("n", "<leader>bca", "<cmd>%bd|e#<cr>", { desc = "Close all buffes except current one" })

-- Telescope
vim.keymap.set("n", "<leader>uu", "<cmd>Telescope undo<cr>", { desc = "Show undoo tree" })

-- Keep matches center screen when cycling
vim.keymap.set("n", "<C-d>", "<C-d>zz", { desc = "Keep cursor in middle when jumping" })
vim.keymap.set("n", "<C-u>", "<C-u>zz", { desc = "Keep cursor in middle when jumping" })
vim.keymap.set("n", "J", "mzJ`z", { desc = "Keep cusors in middle" })
vim.keymap.set("n", "n", "nzzzv", { desc = "Fwd  search '/' or '?'" })
vim.keymap.set("n", "N", "Nzzzv", { desc = "Back search '/' or '?'" })

-- Toggle floating windows
vim.keymap.set("n", "<leader>tt", function()
	Util.float_term({ "gdu" }, { cwd = Util.get_root(), esc_esc = false })
end, { desc = "Toggle: Go Disk Usage" })
vim.keymap.set("n", "<leader>tu", function()
	Util.float_term({ "btm" }, { cwd = Util.get_root(), esc_esc = false })
end, { desc = "Toggle: Bottom" })
vim.keymap.set("n", "<leader>tr", function()
	Util.float_term({ "ranger" }, { cwd = Util.get_root(), esc_esc = false })
end, { desc = "Toggle ranger" })

-- vim.keymap.set("n", "<A-J>", "mzJ`z", { desc = "combine with line up" })

-- Newlines
vim.keymap.set("n", "<leader>o", 'o<Esc>0"_D', { desc = "Create a new line below without leaving normal mode" })
vim.keymap.set("n", "<leader>O", 'O<Esc>0"_D', { desc = "Create a new line above without leaving normal mode" })

-- Tmux
local function map(mode, lhs, rhs, opts)
	local keys = require("lazy.core.handler").handlers.keys
	---@cast keys LazyKeysHandler
	-- do not create the keymap if a lazy keys handler exists
	if not keys.active[keys.parse({ lhs, mode = mode }).id] then
		opts = opts or {}
		opts.silent = opts.silent ~= false
		vim.keymap.set(mode, lhs, rhs, opts)
	end
end

-- buffer
map("n", "<S-A-h>", "<cmd>BufferLineCyclePrev<cr>", { desc = "Prev buffer" })
map("n", "<S-A-l>", "<cmd>BufferLineCycleNext<cr>", { desc = "Next buffer" })

map("n", "<C-h>", "<cmd>lua require'tmux'.move_left()<cr>", { desc = "Go to left window" })
map("n", "<C-j>", "<cmd>lua require'tmux'.move_bottom()<cr>", { desc = "Go to lower window" })
map("n", "<C-k>", "<cmd>lua require'tmux'.move_top()<cr>", { desc = "Go to upper window" })
map("n", "<C-l>", "<cmd>lua require'tmux'.move_right()<cr>", { desc = "Go to right window" })

map("n", "<A-h>", "<cmd>lua require'tmux'.resize_left()<cr>", { desc = "Resize pane left" })
map("n", "<A-j>", "<cmd>lua require'tmux'.resize_bottom()<cr>", { desc = "Resize pane down" })
map("n", "<A-k>", "<cmd>lua require'tmux'.resize_top()<cr>", { desc = "Resize pane up" })
map("n", "<A-l>", "<cmd>lua require'tmux'.resize_right()<cr>", { desc = "Resize pane right" })

-- Move Lines (overwrite lazy vim)
map("n", "<S-A-j>", "<cmd>m .+1<cr>==", { desc = "Move down" })
map("n", "<S-A-k>", "<cmd>m .-2<cr>==", { desc = "Move up" })
map("i", "<S-A-j>", "<esc><cmd>m .+1<cr>==gi", { desc = "Move down" })
map("i", "<S-A-k>", "<esc><cmd>m .-2<cr>==gi", { desc = "Move up" })
map("v", "<S-A-j>", ":m '>+1<cr>gv=gv", { desc = "Move down" })
map("v", "<S-A-k>", ":m '<-2<cr>gv=gv", { desc = "Move up" })

-- Telekasten

vim.keymap.set("n", "<leader>zz", "<cmd>Telekasten panel<CR>")
vim.keymap.set("n", "<leader>zf", "<cmd>Telekasten find_notes<CR>")
vim.keymap.set("n", "<leader>zg", "<cmd>Telekasten search_notes<CR>")
vim.keymap.set("n", "<leader>zd", "<cmd>Telekasten goto_today<CR>")
vim.keymap.set("n", "<leader>zz", "<cmd>Telekasten follow_link<CR>")
vim.keymap.set("n", "<leader>zn", "<cmd>Telekasten new_note<CR>")
vim.keymap.set("n", "<leader>zc", "<cmd>Telekasten show_calendar<CR>")
vim.keymap.set("n", "<leader>zb", "<cmd>Telekasten show_backlinks<CR>")
vim.keymap.set("n", "<leader>zI", "<cmd>Telekasten insert_img_link<CR>")
vim.keymap.set("i", "[[", "<cmd>Telekasten insert_link<CR>")
