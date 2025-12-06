vim.opt.switchbuf = "useopen,uselast"
vim.opt.foldlevel = 99
vim.opt.foldlevelstart = 99
vim.opt.foldenable = true
vim.opt.winwidth = 10
vim.opt.winminwidth = 10
vim.opt.equalalways = true
vim.opt.swapfile = false
vim.opt.incsearch = true

vim.opt.list = true
vim.opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" }

vim.opt.hlsearch = true
vim.opt.inccommand = "split"
vim.opt.scrolloff = 10

vim.o.smarttab = true
vim.opt.cpoptions:append("I")
vim.o.expandtab = true
vim.o.smartindent = true
vim.o.autoindent = true
vim.o.tabstop = 4
vim.o.softtabstop = 4
vim.o.shiftwidth = 4

vim.o.breakindent = true
vim.o.undofile = true

vim.o.ignorecase = true
vim.o.smartcase = true

vim.opt.number = true
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

vim.o.updatetime = 250
vim.o.timeoutlen = 500

vim.o.completeopt = "menu,preview,noselect"
vim.o.termguicolors = true

vim.opt.clipboard = "unnamedplus"

vim.g.netrw_liststyle = 0
vim.g.netrw_banner = 0

vim.diagnostic.config({
	virtual_text = {
		prefix = "●",
	},
	severity_sort = true,
	float = {
		source = "if_many",
	},
})

-- Custom markdown fold expression based on header levels
-- This provides hierarchical folding for markdown headers
function _G.MarkdownFold()
	local line = vim.fn.getline(vim.v.lnum)
	
	-- ATX-style headers (# Header)
	local atx_match = line:match("^(#+)%s")
	if atx_match then
		return ">" .. #atx_match
	end
	
	-- Setext-style headers (underlined with = or -)
	local next_line = vim.fn.getline(vim.v.lnum + 1)
	if next_line:match("^=+%s*$") then
		return ">1"
	elseif next_line:match("^-+%s*$") then
		return ">2"
	end
	
	return "="
end

-- Markdown folding configuration
vim.api.nvim_create_autocmd("FileType", {
	pattern = "markdown",
	callback = function()
		vim.opt_local.foldmethod = "expr"
		vim.opt_local.foldexpr = "v:lua.MarkdownFold()"
		-- Simpler foldtext that shows the header content
		vim.opt_local.foldtext = ""
	end,
})
