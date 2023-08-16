return {
	{
		"nvim-treesitter/nvim-treesitter",
		opts = function(_, opts)
			vim.list_extend(opts.ensure_installed, {
				"c",
				"css",
				"bash",
				"dockerfile",
				"go",
				"gomod",
				"gosum",
				"fish",
				"html",
				"javascript",
				"json",
				"lua",
				"nix",
				"markdown",
				"python",
				"svelte",
				"sql",
				"terraform",
				"typescript",
				"vim",
				"yaml",
			})
		end,
	},

	{
		"williamboman/mason-lspconfig.nvim",
		-- overrides `require("mason-lspconfig").setup(...)`
		opts = {
			ensure_installed = {
				"golangci_lint_ls",
				"gopls",
				"jsonls",
				"nil_ls",
				"lua_ls",
				"tsserver",
			},
		},
	},

	{
		"jay-babu/mason-null-ls.nvim",
		-- overrides `require("mason-null-ls").setup(...)`
		opts = {
			ensure_installed = {
				"eslint_d",
				"flake8",
				"golangci-lint",
				"black",
				"goimports",
				"shfmt",
				"stylua",
			},
		},
	},

	{
		"jay-babu/mason-nvim-dap.nvim",
		-- overrides `require("mason-nvim-dap").setup(...)`
		opts = function(_, opts)
			-- add more things to the ensure_installed table protecting against community packs modifying it
			vim.list_extend(opts.ensure_installed, {
				"debugpy",
				"delve",
				"go-debug-adapter",
			})
		end,
	},
}
