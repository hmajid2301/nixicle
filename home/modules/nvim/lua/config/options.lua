-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here
vim.g.mapleader = " "

vim.opt.timeoutlen = 100
vim.opt.hlsearch = false
vim.opt.incsearch = true
vim.opt.colorcolumn = "120"
vim.opt.swapfile = false
vim.opt.scrolloff = 8
vim.opt.updatetime = 50

-- Highlight groups for illuminate
vim.api.nvim_set_hl(0, "IlluminatedWordText", { link = "Visual" })
vim.api.nvim_set_hl(0, "IlluminatedWordRead", { link = "Visual" })
vim.api.nvim_set_hl(0, "IlluminatedWordWrite", { link = "Visual" })
