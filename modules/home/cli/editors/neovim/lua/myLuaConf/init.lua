-- NOTE: various, non-plugin config
require("myLuaConf.opts_and_keys")

-- NOTE: register an extra lze handler with the spec_field 'for_cat'
-- that makes enabling an lze spec for a category slightly nicer
require("lze").register_handlers(require("nixCatsUtils.lzUtils").for_cat)

-- NOTE: Register another one from lzextras. This one makes it so that
-- you can set up lsps within lze specs,
-- and trigger lspconfig setup hooks only on the correct filetypes
require("lze").register_handlers(require("lzextras").lsp)

-- NOTE: general plugins
require("myLuaConf.plugins")
require("myLuaConf.plugins.colorscheme")

-- NOTE: obviously, more plugins, but more organized by what they do below

-- I dont need to explain why this is called lsp right?
require("myLuaConf.LSPs")

-- NOTE: we even ask nixCats if we included our debug stuff in this setup! (we didnt)
-- But we have a good base setup here as an example anyway!
if nixCats("debug") then
	require("myLuaConf.debug")
end
if nixCats("test") then
	require("myLuaConf.test")
end
-- NOTE: we included these though! Or, at least, the category is enabled.
-- these contain nvim-lint and conform setups.
if nixCats("lint") then
	require("myLuaConf.lint")
end
if nixCats("format") then
	require("myLuaConf.format")
end
-- NOTE: I didnt actually include any linters or formatters in this configuration,
-- but it is enough to serve as an example.

-- NOTE: Show random tip on startup
local utils = require("myLuaConf.utils")
vim.api.nvim_create_autocmd("VimEnter", {
	group = vim.api.nvim_create_augroup("ShowTips", { clear = true }),
	callback = function()
		-- Only show tips if no files were opened
		if vim.fn.argc() == 0 then
			utils.show_tip()
		end
	end,
	desc = "Show random tip from tips.md on startup",
})
