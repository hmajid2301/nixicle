vim.cmd.colorscheme("catppuccin")

-- put this in your main init.lua file ( before lazy setup )
vim.g.base46_cache = vim.fn.stdpath("data") .. "/base46_cache/"

dofile(vim.g.base46_cache .. "defaults")
dofile(vim.g.base46_cache .. "statusline")

vim.hl = vim.highlight

-- require("catppuccin").setup({
-- 	flavour = "mocha",
-- 	integrations = {
-- 		-- gitsigns = true,
-- 		-- illuminate = true,
-- 		-- grug_far = true,
-- 		-- indent_blankline = true,
-- 		-- mini = true,
-- 		-- navic = true,
-- 		-- telescope = true,
-- 		-- neotest = true,
-- 		-- flash = true,
-- 		-- treesitter = true,
-- 		-- treesitter_context = true,
-- 	},
-- })

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
	{
		"lazydev.nvim",
		for_cat = "neonixdev",
		cmd = { "LazyDev" },
		ft = "lua",
		after = function(plugin)
			require("lazydev").setup({
				library = {
					{ words = { "nixCats" }, path = (require("nixCats").nixCatsPath or "") .. "/lua" },
				},
			})
		end,
	},
})
