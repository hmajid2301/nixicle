-- NOTE: various, non-plugin config
require("myLuaConf.opts_and_keys")

-- NOTE: Enable treesitter highlighting for main branch
-- Must be in init.lua because treesitter plugin loads on DeferredUIEnter,
-- but we need highlighting to work for files opened at startup
vim.api.nvim_create_autocmd("FileType", {
	pattern = "*",
	callback = function(args) 
		-- Add error handling to prevent crashes during session restore
		local success, err = pcall(function()
			-- Check if parser is available before starting
			local lang = vim.bo[args.buf].filetype
			local ts_lang = vim.treesitter.language.get_lang(lang)
			if ts_lang then
				vim.treesitter.start(args.buf)
			end
		end)
		if not success then
			-- Silently fail if treesitter can't start for this buffer
			vim.notify("Treesitter failed to start for " .. vim.bo[args.buf].filetype .. ": " .. err, vim.log.levels.DEBUG)
		end
	end,
})

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
