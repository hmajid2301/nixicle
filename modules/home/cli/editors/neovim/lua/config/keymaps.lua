vim.g.mapleader = " "
vim.g.maplocalleader = ","

vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR>")

vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv", { desc = "Moves Line Down" })
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv", { desc = "Moves Line Up" })
vim.keymap.set("n", "<C-d>", "<C-d>zz", { desc = "Scroll Down / Keep cursor centered" })
vim.keymap.set("n", "<C-u>", "<C-u>zz", { desc = "Scroll Up / Keep cursor centered" })
vim.keymap.set("n", "n", "nzzzv", { desc = "Next Search Result / Keep cursor centered" })
vim.keymap.set("n", "N", "Nzzzv", { desc = "Previous Search Result / Keep cursor centered" })

vim.keymap.set("n", "<leader><leader>[", "<cmd>bprev<CR>", { desc = "Previous buffer" })
vim.keymap.set("n", "<leader><leader>]", "<cmd>bnext<CR>", { desc = "Next buffer" })
vim.keymap.set("n", "<leader><leader>l", "<cmd>b#<CR>", { desc = "Last buffer" })
vim.keymap.set("n", "<leader><leader>d", "<cmd>bdelete<CR>", { desc = "Delete buffer" })

vim.keymap.set("n", "k", "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })
vim.keymap.set("n", "j", "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })

vim.keymap.set("n", "[d", function()
	vim.diagnostic.jump({ count = -1 })
end, { desc = "Go to previous diagnostic message" })
vim.keymap.set("n", "]d", function()
	vim.diagnostic.jump({ count = 1 })
end, { desc = "Go to next diagnostic message" })

vim.keymap.set("n", "<leader>cd", vim.diagnostic.open_float, { desc = "Open floating diagnostic message" })
vim.keymap.set("n", "<leader>q", vim.diagnostic.setloclist, { desc = "Open diagnostics list" })

vim.keymap.set("i", "<C-p>", "<C-r><C-p>+", { noremap = true, silent = true, desc = "Paste from clipboard in insert mode" })

vim.keymap.set("n", "<leader>mj", ":m .+1<CR>==", { desc = "Move line down" })
vim.keymap.set("n", "<leader>mk", ":m .-2<CR>==", { desc = "Move line up" })
vim.keymap.set("v", "<leader>mj", ":m '>+1<CR>gv=gv", { desc = "Move selected lines down" })
vim.keymap.set("v", "<leader>mk", ":m '<-2<CR>gv=gv", { desc = "Move selected lines up" })

vim.keymap.set("n", "J", "mzJ`z", { desc = "Combine line into one" })

vim.keymap.set("n", "<leader>|", "<C-w>v", { desc = "Split window right" })
vim.keymap.set("n", "<leader>-", "<C-w>s", { desc = "Split window below" })

vim.keymap.set({ "n", "v", "x" }, "<C-s>", "<cmd>w<cr><esc>", { desc = "Save file" })

vim.keymap.set({ "v", "x" }, ">", ">gv", { desc = "Stay in visual mode during outdent" })
vim.keymap.set({ "v", "x" }, "<", "<gv", { desc = "Stay in visual mode during indent" })

vim.keymap.set("n", "<C-n>", "<cmd>cnext<CR>zz", { desc = "Go to next item in quickfix list" })
vim.keymap.set("n", "<C-p>", "<cmd>cprev<CR>zz", { desc = "Go to previous item in quickfix list" })
vim.keymap.set("n", "<leader>k", "<cmd>lnext<CR>zz", { desc = "Go to next item in location list" })
vim.keymap.set("n", "<leader>j", "<cmd>lprev<CR>zz", { desc = "Go to previous item in location list" })

-- Open current file in external terminal (useful for image preview)
vim.keymap.set("n", "<leader>tt", function()
	local current_file = vim.fn.expand("%:p")
	local line = vim.fn.line(".")
	local col = vim.fn.col(".")

	if current_file == "" or vim.bo.buftype ~= "" then
		vim.notify("No file to open in external terminal", vim.log.levels.WARN)
		return
	end

	local script = vim.fn.expand("$HOME/.local/bin/open-in-terminal")
	local cmd

	if vim.fn.executable(script) == 1 then
		cmd = string.format("%s '%s' %d %d &", script, current_file, line, col)
	else
		cmd = string.format("ghostty -e nvim '+call cursor(%d,%d)' '%s' &", line, col, current_file)
	end

	vim.fn.system(cmd)
	vim.notify("Opened in new terminal: " .. vim.fn.fnamemodify(current_file, ":t"), vim.log.levels.INFO)
end, { desc = "Open current file in new terminal" })
