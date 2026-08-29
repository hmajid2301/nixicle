require("config.opts_and_keys")

-- Register the for_cat lze handler so specs can use for_cat = "specname"
require("lze").register_handlers(require("nix_utils").for_cat_handler)

-- Register lzextras lsp handler for LSP-triggered lazy loading
require("lze").register_handlers(require("lzextras").lsp)

-- General plugins
require("config.plugins")
require("config.plugins.colorscheme")

-- LSP configurations
require("config.LSPs")

if nixInfo(false, "settings", "cats", "debug") then
	require("config.debug")
end
if nixInfo(false, "settings", "cats", "test") then
	require("config.test")
end
if nixInfo(false, "settings", "cats", "lint") then
	require("config.lint")
end
if nixInfo(false, "settings", "cats", "format") then
	require("config.format")
end
