require("lze").load({
	{
		"nvim-lint",
		for_cat = "lint",
		event = "FileType",
		after = function(plugin)
			require("lint").linters_by_ft = {
				docker = { "hadolint" },
				go = { "golangcilint" },
				html = { "htmlhint" },
				lua = { "luacheck" },
				nix = { "statix" },
				javascript = { "eslint" },
				typescript = { "eslint" },
				sql = { "sqlfluff" },
				terraform = { "tflint", "tfsec" },
			}

			vim.api.nvim_create_autocmd({ "BufWritePost" }, {
				callback = function()
					require("lint").try_lint()
				end,
			})
		end,
	},
})
