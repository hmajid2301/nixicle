require("lze").load({
	{
		"nvim-lint",
		for_cat = "lint",
		-- cmd = { "" },
		event = "FileType",
		-- ft = "",
		-- keys = "",
		-- colorscheme = "",
		after = function(plugin)
			require("lint").linters_by_ft = {
				-- TODO: css with tailwind
				-- css = { "stylelint" },
				docker = { "hadolint" },
				go = { "golangcilint" },
				html = { "htmlhint" },
				lua = { "luacheck" },
				-- markdown = { "markdownlint-cli2" },
				nix = { "statix" },
				javascript = { "eslint" },
				typescript = { "eslint" },
				sql = { "sqlfluff" },
				-- TODO: fix yaml
				-- yaml = { "yamllint" },
			}

			vim.api.nvim_create_autocmd({ "BufWritePost" }, {
				callback = function()
					require("lint").try_lint()
				end,
			})
		end,
	},
})
