require("lze").load({
	{
		"nvim-lint",
		for_cat = "lint",
		event = "FileType",
		after = function(plugin)
			local golint = require("lint").linters.golangcilint

			-- Set up arguments dynamically based on golangci-lint version
			golint.args = (function()
				local ok, value = pcall(vim.fn.system, { "golangci-lint", "version" })
				if ok and (string.find(value, "version v2") or string.find(value, "version 2")) then
					return {
						"run",
						"--output.json.path=stdout",
						"--issues-exit-code=0",
						"--show-stats=false",
						-- Use a function to dynamically get the current buffer's directory
						function()
							return vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ":h")
						end,
					}
				else
					return {
						"run",
						"--out-format",
						"json",
						"--issues-exit-code=0",
						"--show-stats=false",
						"--print-issued-lines=false",
						"--print-linter-name=false",
						function()
							return vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ":h")
						end,
					}
				end
			end)()

			-- Set linters for different file types
			require("lint").linters_by_ft = {
				docker = { "hadolint" },
				go = { "golangcilint" },
				html = { "htmlhint" },
				lua = { "luacheck" },
				nix = { "statix" },
				javascript = { "eslint" },
				typescript = { "eslint" },
				sql = { "sqlfluff" },
			}

			-- Auto-run linting on save
			vim.api.nvim_create_autocmd({ "BufWritePost" }, {
				callback = function()
					require("lint").try_lint()
				end,
			})
		end,
	},
})
