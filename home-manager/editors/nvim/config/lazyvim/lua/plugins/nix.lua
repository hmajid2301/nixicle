return {
	-- Correctly setup lspconfig for Nix 🚀
	{
		"neovim/nvim-lspconfig",
		opts = {
			servers = {
				-- Ensure mason installs the server
				nil_ls = {},
			},
			settings = {
				nil_ls = {},
			},
		},
	},

	{
		"jose-elias-alvarez/null-ls.nvim",
		opts = function(_, opts)
			local nls = require("null-ls")
			if type(opts.sources) == "table" then
				vim.list_extend(opts.sources, {
					nls.builtins.code_actions.statix,
					nls.builtins.formatting.alejandra,
					nls.builtins.diagnostics.deadnix,
				})
			end
		end,
	},
	{
		"calops/hmts.nvim",
		ft = "nix",
	},
}
