-- load the plugins via paq-nvim when not on nix
-- YOU are in charge of putting the plugin
-- urls and build steps in there, which will only be used when not on nix,
-- and you should keep any setup functions
-- OUT of that file, as they are ONLY loaded when this
-- configuration is NOT loaded via nix.
require("nixCatsUtils.catPacker").setup({
	{ "BirdeeHub/lze" },
	{ "stevearc/oil.nvim" },
	{ "joshdick/onedark.vim" },
	{ "nvim-tree/nvim-web-devicons" },
	{ "nvim-lua/plenary.nvim" },
	{ "tpope/vim-repeat" },

	{ "nvim-treesitter/nvim-treesitter-textobjects", opt = true },
	{ "nvim-treesitter/nvim-treesitter", build = ":TSUpdate", opt = true },

	{ "nvim-telescope/telescope-fzf-native.nvim", build = ":!which make && make", opt = true },
	{ "nvim-telescope/telescope.nvim", opt = true },

	-- lsp
	{ "williamboman/mason.nvim", opt = true },
	{ "williamboman/mason-lspconfig.nvim", opt = true },
	{ "j-hui/fidget.nvim", opt = true },
	{ "neovim/nvim-lspconfig", opt = true },

	--  NOTE:  we take care of lazy loading elsewhere in an autocommand
	-- so that we can use the same code on and off nix.
	-- so here we just tell it not to auto load it
	{ "folke/lazydev.nvim", opt = true },

	-- completion
	{ "onsails/lspkind.nvim", opt = true },
	{ "L3MON4D3/LuaSnip", opt = true, as = "luasnip" },
	{ "saadparwaiz1/cmp_luasnip", opt = true },
	{ "hrsh7th/cmp-nvim-lsp", opt = true },
	{ "hrsh7th/cmp-nvim-lua", opt = true },
	{ "hrsh7th/cmp-nvim-lsp-signature-help", opt = true },
	{ "hrsh7th/cmp-path", opt = true },
	{ "rafamadriz/friendly-snippets", opt = true },
	{ "hrsh7th/cmp-buffer", opt = true },
	{ "hrsh7th/cmp-cmdline", opt = true },
	{ "dmitmel/cmp-cmdline-history", opt = true },
	{ "hrsh7th/nvim-cmp", opt = true },
	{ "MattiasMTS/cmp-dbee", opt = true },

	-- lint and format
	{ "mfussenegger/nvim-lint", opt = true },
	{ "stevearc/conform.nvim", opt = true },

	-- dap
	{ "nvim-neotest/nvim-nio", opt = true },
	{ "rcarriga/nvim-dap-ui", opt = true },
	{ "jay-babu/mason-nvim-dap.nvim", opt = true },
	{ "mfussenegger/nvim-dap", opt = true },
	{ "leoluz/nvim-dap-go", opt = true },

	-- neotest
	{ "nvim-neotest/neotest", opt = true },
	{ "fredrikaverpil/neotest-golang", opt = true },
	{ "nvim-neotest/neotest-python", opt = true },

	-- Database
	{ "kndndrj/nvim-dbee", opt = true },

	-- Git
	{ "lewis6991/gitsigns.nvim", opt = true },
	{ "sindrets/diffview.nvim", opt = true },
	{ "aaronhallaert/advanced-git-search.nvim", opt = true },
	{ "NeogitOrg/neogit", opt = true },

	-- ai
	{ "CopilotC-Nvim/CopilotChat.nvim", opt = true },

	-- extra
	{ "rmagatti/auto-session", opt = true },

	-- ui
	{ "nvim-lualine/lualine.nvim", opt = true },
	{ "utilyre/barbecue.nvim", opt = true },
	{ "NvChad/ui", opt = true },
	{ "NvChad/base46", opt = true },

	-- editor
	{ "folke/trouble.nvim", opt = true },
	{ "echasnovski/mini.nvim", opt = true },
	{ "ThePrimeagen/refactoring.nvim", opt = true },
	{ "otavioschwanck/arrow.nvim", opt = true },
	{ "RRethy/vim-illuminate", opt = true },
	{ "folke/todo-comments.nvim", opt = true },
	{ "lukas-reineke/indent-blankline.nvim", opt = true },
	{ "MagicDuck/grug-far.nvim", opt = true },
	{ "mrjones2014/smart-splits.nvim", opt = true },
	{ "mbbill/undotree", opt = true },
	{ "chrishrb/gx.nvim", opt = true },
})
