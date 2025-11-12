require("nixCatsUtils.catPacker").setup({
	{ "BirdeeHub/lze" },
	{ "BirdeeHub/lzextras" },
	{ "tpope/vim-repeat" },
	{ "nvim-lua/plenary.nvim" },
	{ "stevearc/oil.nvim" },
	{ "b0o/SchemaStore.nvim" },
	{ "nvim-tree/nvim-web-devicons" },
	{ "rmagatti/auto-session" },

	{ "catppuccin/nvim", as = "catppuccin" },

	{ "nvim-neotest/nvim-nio", opt = true },
	{ "mfussenegger/nvim-dap", opt = true },
	{ "Mgenuit/nvim-dap-view", opt = true },
	{ "leoluz/nvim-dap-go", opt = true },
	{ "Willem-J-an/nvim-debug-master", opt = true },

	{ "nvim-neotest/neotest", opt = true },
	{ "fredrikaverpil/neotest-golang", opt = true },
	{ "andythigpen/nvim-coverage", opt = true },
	{ "tpope/vim-dotenv", opt = true },

	{ "mfussenegger/nvim-lint", opt = true },
	{ "stevearc/conform.nvim", opt = true },

	{ "folke/lazydev.nvim", opt = true },

	{ "saghen/blink.cmp", opt = true },
	{ "saghen/blink.compat", opt = true },
	{ "mikavilpas/blink-ripgrep.nvim", opt = true },
	{ "giuxtaposition/blink-cmp-avante", opt = true },
	{ "L3MON4D3/LuaSnip", opt = true },
	{ "rafamadriz/friendly-snippets", opt = true },
	{ "onsails/lspkind.nvim", opt = true },
	{ "MattiasMTS/cmp-dbee", opt = true },
	{ "samiulsami/cmp-go-deep", opt = true },
	{ "kkharji/sqlite.lua", opt = true },

	{ "nvim-treesitter/nvim-treesitter-textobjects", opt = true },
	{ "nvim-treesitter/nvim-treesitter", build = ":TSUpdate", opt = true },

	{ "nvim-telescope/telescope-fzf-native.nvim", build = ":!which make && make", opt = true },
	{ "nvim-telescope/telescope-media-files.nvim", opt = true },
	{ "nvim-telescope/telescope-ui-select.nvim", opt = true },
	{ "nvim-telescope/telescope.nvim", opt = true },

	{ "neovim/nvim-lspconfig", opt = true },

	{ "lewis6991/gitsigns.nvim", opt = true },
	{ "sindrets/diffview.nvim", opt = true },
	{ "aaronhallaert/advanced-git-search.nvim", opt = true },
	{ "NeogitOrg/neogit", opt = true },
	{ "brandoncc/git-worktree.nvim", branch = "catch-and-handle-telescope-related-error", opt = true },
	{ "pabloariasal/webify.nvim", opt = true },

	{ "folke/trouble.nvim", opt = true },

	{ "echasnovski/mini.nvim", opt = true },
	{ "Rolv-Apneseth/fyler.nvim", opt = true },
	{ "ThePrimeagen/refactoring.nvim", opt = true },
	{ "otavioschwanck/arrow.nvim", opt = true },
	{ "RRethy/vim-illuminate", opt = true },
	{ "SmiteshP/nvim-navic", opt = true },
	{ "folke/todo-comments.nvim", opt = true },
	{ "MagicDuck/grug-far.nvim", opt = true },
	{ "mrjones2014/smart-splits.nvim", opt = true },
	{ "gbprod/yanky.nvim", opt = true },
	{ "smjonas/inc-rename.nvim", opt = true },
	{ "folke/snacks.nvim", opt = true },
	{ "chrishrb/gx.nvim", opt = true },
	{ "catgoose/templ-goto-definition", opt = true },
	{ "rachartier/tiny-code-action.nvim", opt = true },
	{ "AndrewRadev/inline_edit.vim", opt = true },

	{ "j-hui/fidget.nvim", opt = true },
	{ "numToStr/Comment.nvim", opt = true },
	{ "mbbill/undotree", opt = true },
	{ "kndndrj/nvim-dbee", opt = true },

	{ "OXY2DEV/markview.nvim", opt = true },

	{ "lukas-reineke/indent-blankline.nvim", opt = true },
	{ "nvim-lualine/lualine.nvim", opt = true },
	{ "Bekaboo/dropbar.nvim", opt = true },
	{ "OXY2DEV/helpview.nvim", opt = true },
	{ "brenoprata10/nvim-highlight-colors", opt = true },

	{ "supermaven-inc/supermaven-nvim", opt = true },
})
