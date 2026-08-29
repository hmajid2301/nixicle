require("lze").load({
	{
		"nvim-lint",
		for_cat = "lint",
		event = "FileType",
		after = function(plugin)
			local lint = require("lint")

			-- Customize golangci-lint to handle exit codes properly
			-- Exit code 3 means issues found, which is not an error
			lint.linters.golangcilint.args = {
				"run",
				"--out-format=json",
				"--issues-exit-code=0", -- Don't exit with error when issues found
			}

			lint.linters_by_ft = {
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
