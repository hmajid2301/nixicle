-- local colorschemeName = nixCats("colorscheme")
-- if not require("nixCatsUtils").isNixCats then
-- 	colorschemeName = "catppuccin"
-- end
-- -- Could I lazy load on colorscheme with lze?
-- -- sure. But I was going to call vim.cmd.colorscheme() during startup anyway
-- -- this is just an example, feel free to do a better job!
-- vim.cmd.colorscheme(colorschemeName)

-- put this in your main init.lua file ( before lazy setup )
vim.g.base46_cache = vim.fn.stdpath("data") .. "/base46_cache/"

require("catppuccin").setup({
	flavour = "mocha",
	integrations = {
		-- gitsigns = true,
		illuminate = {
			enabled = true,
		},
		-- grug_far = true,
		-- indent_blankline = true,
		-- mini = true,
		-- navic = true,
		-- telescope = true,
		-- neotest = true,
		-- flash = true,
		-- treesitter = true,
		-- treesitter_context = true,
	},
})

-- TODO: lazyload this
require("auto-session").setup({})

require("lze").load({
	{ import = "myLuaConf.plugins.telescope" },
	{ import = "myLuaConf.plugins.treesitter" },
	{ import = "myLuaConf.plugins.completion" },
	{ import = "myLuaConf.plugins.diagnostics" },
	{ import = "myLuaConf.plugins.editor" },
	{ import = "myLuaConf.plugins.file_explorer" },
	{ import = "myLuaConf.plugins.git" },
	{ import = "myLuaConf.plugins.ai" },
	{ import = "myLuaConf.plugins.ui" },
})

dofile(vim.g.base46_cache .. "defaults")
dofile(vim.g.base46_cache .. "statusline")
