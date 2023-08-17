

local plugins = {
	{
		"ray-x/go.nvim",
		dependencies = { -- optional packages
			"ray-x/guihua.lua",
			"neovim/nvim-lspconfig",
			"nvim-treesitter/nvim-treesitter",
		},
		config = function()
			require("go").setup()
		end,
		event = { "cmdlineenter" },
		ft = { "go", "gomod" },
		build = ':lua require("go.install").update_all_sync()', -- if you need to install/update all binaries
	},
  {
		"max397574/better-escape.nvim",
		event = "InsertCharPre",
		opts = { timeout = 300 },
	},
  -- {
  -- "neovim/nvim-lspconfig",
  --  config = function()
  --     -- require "plugins.configs.lspconfig"
  --     require "custom.configs.lspconfig"
  --  end,
  -- },
	{
		"calops/hmts.nvim",
		ft = "nix",
	},
  {
		"aserowy/tmux.nvim",
		opts = {},
		event = "VimEnter",
	},
  {
		"anuvyklack/windows.nvim",
		dependencies = {
			"anuvyklack/middleclass",
			"anuvyklack/animation.nvim",
		},
		opts = {},
		cmd = {
			"WindowsMaximize",
			"WindowsMaximizeVertically",
			"WindowsMaximizeHorizontally",
			"WindowsEqualize",
			"WindowsEnableAutowidth",
			"WindowsDisableAutowidth",
			"WindowsToggleAutowidth",
		},
		init = function()
			vim.o.winwidth = 10
			vim.o.winminwidth = 10
			vim.o.equalalways = false
		end,
	},
}

return plugins
