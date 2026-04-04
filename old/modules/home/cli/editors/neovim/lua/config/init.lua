require("config.opts_and_keys")

-- NOTE: register an extra lze handler with the spec_field 'for_cat'
-- that makes enabling an lze spec for a category slightly nicer
require("lze").register_handlers(require("nixCatsUtils.lzUtils").for_cat)

-- NOTE: Register another one from lzextras. This one makes it so that
-- you can set up lsps within lze specs,
-- and trigger lspconfig setup hooks only on the correct filetypes
require("lze").register_handlers(require("lzextras").lsp)

-- NOTE: general plugins
require("config.plugins")
require("config.plugins.colorscheme")

-- NOTE: obviously, more plugins, but more organized by what they do below

-- I dont need to explain why this is called lsp right?
require("config.LSPs")

-- NOTE: we even ask nixCats if we included our debug stuff in this setup! (we didnt)
-- But we have a good base setup here as an example anyway!
if nixCats("debug") then
	require("config.debug")
end
if nixCats("test") then
	require("config.test")
end
-- NOTE: we included these though! Or, at least, the category is enabled.
-- these contain nvim-lint and conform setups.
if nixCats("lint") then
	require("config.lint")
end
if nixCats("format") then
	require("config.format")
end
-- NOTE: I didnt actually include any linters or formatters in this configuration,
-- but it is enough to serve as an example.
