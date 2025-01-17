-- NOTE: These 2 need to be set up before any plugins are loaded.
vim.g.mapleader = " "
vim.g.maplocalleader = ","

if os.getenv("WAYLAND_DISPLAY") and vim.fn.exepath("wl-copy") ~= "" then
	vim.g.clipboard = {
		name = "wl-clipboard",
		copy = {
			["+"] = "wl-copy",
			["*"] = "wl-copy",
		},
		paste = {
			["+"] = "wl-paste",
			["*"] = "wl-paste",
		},
		cache_enabled = 1,
	}
end
-- [[ Setting options ]]
-- See `:help vim.o`
-- NOTE: You can change these options as you wish!
vim.opt.sessionoptions = "blank,buffers,curdir,folds,help,tabpages,winsize,winpos,terminal,localoptions"
vim.opt.switchbuf = "useopen,uselast"
vim.opt.foldlevel = 99
vim.opt.foldlevelstart = 99
vim.opt.foldenable = true
vim.opt.winwidth = 10
vim.opt.winminwidth = 10
vim.opt.equalalways = true
vim.opt.swapfile = false
vim.opt.incsearch = true

-- Sets how neovim will display certain whitespace characters in the editor.
--  See `:help 'list'`
--  and `:help 'listchars'`

vim.opt.list = true
vim.opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" }

-- Set highlight on search
vim.opt.hlsearch = true
vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR>")

-- Preview substitutions live, as you type!
vim.opt.inccommand = "split"

-- Minimal number of screen lines to keep above and below the cursor.
vim.opt.scrolloff = 10

-- Indent
vim.o.smarttab = true
vim.opt.cpoptions:append("I")
vim.o.expandtab = true
vim.o.smartindent = true
vim.o.autoindent = true
vim.o.tabstop = 4
vim.o.softtabstop = 4
vim.o.shiftwidth = 4

-- stops line wrapping from being confusing
vim.o.breakindent = true

-- Save undo history
vim.o.undofile = true

-- Case-insensitive searching UNLESS \C or capital in search
vim.o.ignorecase = true
vim.o.smartcase = true

-- Make line numbers default
vim.opt.number = true
-- Keep signcolumn on by default
vim.opt.signcolumn = "yes"
vim.opt.relativenumber = true
vim.opt.cursorline = true
vim.opt.numberwidth = 2

vim.opt.cmdheight = 1
vim.opt.colorcolumn = "120"
vim.opt.splitbelow = true
vim.opt.splitright = true
vim.opt.undofile = true
vim.opt.ruler = false

-- Decrease update time
vim.o.updatetime = 250
vim.o.timeoutlen = 1000

-- Set completeopt to have a better completion experience
vim.o.completeopt = "menu,preview,noselect"

-- NOTE: You should make sure your terminal supports this
vim.o.termguicolors = true

-- [[ Disable auto comment on enter ]]
-- See :help formatoptions
vim.api.nvim_create_autocmd("FileType", {
	desc = "remove formatoptions",
	callback = function()
		vim.opt.formatoptions:remove({ "c", "r", "o" })
	end,
})

-- [[ Highlight on yank ]]
-- See `:help vim.highlight.on_yank()`
local highlight_group = vim.api.nvim_create_augroup("YankHighlight", { clear = true })
vim.api.nvim_create_autocmd("TextYankPost", {
	callback = function()
		vim.highlight.on_yank()
	end,
	group = highlight_group,
	pattern = "*",
})

vim.api.nvim_create_autocmd("BufWritePre", {
	pattern = "*.templ",
	callback = function()
		if vim.bo.filetype == "templ" then
			local bufnr = vim.api.nvim_get_current_buf()
			local filename = vim.api.nvim_buf_get_name(bufnr)
			local cmd = "templ fmt " .. vim.fn.shellescape(filename)

			vim.fn.jobstart(cmd, {
				on_exit = function()
					-- Reload the buffer only if it's still the current buffer
					if vim.api.nvim_get_current_buf() == bufnr then
						vim.cmd("e!")
					end
				end,
			})
		else
			vim.lsp.buf.format()
		end
	end,
})

vim.g.netrw_liststyle = 0
vim.g.netrw_banner = 0
-- [[ Basic Keymaps ]]

-- Keymaps for better default experience
-- See `:help vim.keymap.set()`
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv", { desc = "Moves Line Down" })
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv", { desc = "Moves Line Up" })
vim.keymap.set("n", "<C-d>", "<C-d>zz", { desc = "Scroll Down" })
vim.keymap.set("n", "<C-u>", "<C-u>zz", { desc = "Scroll Up" })
vim.keymap.set("n", "n", "nzzzv", { desc = "Next Search Result" })
vim.keymap.set("n", "N", "Nzzzv", { desc = "Previous Search Result" })

vim.keymap.set("n", "<leader><leader>[", "<cmd>bprev<CR>", { desc = "Previous buffer" })
vim.keymap.set("n", "<leader><leader>]", "<cmd>bnext<CR>", { desc = "Next buffer" })
vim.keymap.set("n", "<leader><leader>l", "<cmd>b#<CR>", { desc = "Last buffer" })
vim.keymap.set("n", "<leader><leader>d", "<cmd>bdelete<CR>", { desc = "delete buffer" })

-- Remap for dealing with word wrap
vim.keymap.set("n", "k", "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })
vim.keymap.set("n", "j", "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })

-- Diagnostic keymaps
vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, { desc = "Go to previous diagnostic message" })
vim.keymap.set("n", "]d", vim.diagnostic.goto_next, { desc = "Go to next diagnostic message" })
vim.keymap.set("n", "<leader>e", vim.diagnostic.open_float, { desc = "Open floating diagnostic message" })
vim.keymap.set("n", "<leader>q", vim.diagnostic.setloclist, { desc = "Open diagnostics list" })

-- kickstart.nvim starts you with this.
-- But it constantly clobbers your system clipboard whenever you delete anything.

-- Sync clipboard between OS and Neovim.
--  Remove this option if you want your OS clipboard to remain independent.
--  See `:help 'clipboard'`
vim.o.clipboard = "unnamedplus"

-- You should instead use these keybindings so that they are still easy to use, but dont conflict
vim.keymap.set("n", "<leader>y", '"+y', { noremap = true, silent = true, desc = "Yank to clipboard" })
vim.keymap.set({ "v", "x" }, "<leader>y", '"+y', { noremap = true, silent = true, desc = "Yank to clipboard" })
vim.keymap.set(
	{ "n", "v", "x" },
	"<leader>yy",
	'"+yy',
	{ noremap = true, silent = true, desc = "Yank line to clipboard" }
)
vim.keymap.set(
	{ "n", "v", "x" },
	"<leader>Y",
	'"+yy',
	{ noremap = true, silent = true, desc = "Yank line to clipboard" }
)
vim.keymap.set({ "n", "v", "x" }, "<C-a>", "gg6vG$", { noremap = true, silent = true, desc = "Select all" })
vim.keymap.set({ "n", "v", "x" }, "<leader>p", '"+p', { noremap = true, silent = true, desc = "Paste from clipboard" })
vim.keymap.set(
	"i",
	"<C-p>",
	"<C-r><C-p>+",
	{ noremap = true, silent = true, desc = "Paste from clipboard from within insert mode" }
)
vim.keymap.set(
	"x",
	"<leader>P",
	'"_dP',
	{ noremap = true, silent = true, desc = "Paste over selection without erasing unnamed register" }
)
vim.keymap.set("n", "<C-d>", "<C-d>zz", { desc = "Keep cursor in middle when jumping" })
vim.keymap.set("n", "<C-u>", "<C-u>zz", { desc = "Keep cursor in middle when jumping" })
vim.keymap.set("n", "<leader>mj", ":m .+1<CR>==", { desc = "Move selected lines down" })
vim.keymap.set("n", "<leader>mk", ":m .-2<CR>==", { desc = "Move selected lines up" })
vim.keymap.set("v", "<leader>mj", ":m '>+1<CR>gv=gv", { desc = "Move selected lines down in visual mode" })
vim.keymap.set("v", "<leader>mk", ":m '<-2<CR>gv=gv", { desc = "Move selected lines up in visual mode" })
vim.keymap.set("n", "J", "mzJ`z", { desc = "Combine line into one" })
vim.keymap.set("n", "n", "nzzzv", { desc = "Keep cursor in middle when searching" })
vim.keymap.set("n", "N", "Nzzzv", { desc = "Keep cursor in middle when searching" })
vim.keymap.set("n", "j", "v:count == 0 ? 'gj' : 'j'", { silent = true, expr = true })
vim.keymap.set("n", "k", "v:count == 0 ? 'gk' : 'k'", { silent = true, expr = true })
vim.keymap.set("n", "<leader>|", "<C-w>v", { desc = "Split window right" })
vim.keymap.set("n", "<leader>-", "<C-w>s", { desc = "Split window below" })
vim.keymap.set({ "n", "v", "x" }, "<C-s>", "<cmd>w<cr><esc>", { desc = "Save file" })
vim.keymap.set("v", "<leader>p", "'_dP", { desc = "Paste without updating buffer" })
vim.keymap.set({ "v", "x" }, ">", ">gv", { desc = "Stay in visual mode during outdent" })
vim.keymap.set({ "v", "x" }, "<", "<gv", { desc = "Stay in visual mode during indent" })
vim.keymap.set("n", "<C-n>", "<cmd>cnext<CR>zz", { desc = "Go to next item in quickfix list and center cursor" })
vim.keymap.set("n", "<C-p>", "<cmd>cprev<CR>zz", { desc = "Go to previous item in quickfix list and center cursor" })
vim.keymap.set("n", "<leader>k", "<cmd>lnext<CR>zz", { desc = "Go to next item in location list and center cursor" })
vim.keymap.set(
	"n",
	"<leader>j",
	"<cmd>lprev<CR>zz",
	{ desc = "Go to previous item in location list and center cursor" }
)
vim.keymap.set("n", "<C-b>", "<cmd>cmp.mapping.scroll_docs(-4)<CR>", { desc = "Scroll docs down" })
vim.keymap.set("n", "<C-f>", "<cmd>cmp.mapping.scroll_docs(4)<CR>", { desc = "Scroll docs up" })
