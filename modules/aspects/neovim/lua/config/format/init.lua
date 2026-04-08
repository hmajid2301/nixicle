require("lze").load({
	{
		"conform.nvim",
		for_cat = "format",
		after = function(plugin)
			local conform = require("conform")

			conform.setup({
				["_"] = { "trim_whitespace" },
				format_on_save = {
					lsp_format = "fallback",
					timeout_ms = 500,
				},
				-- format_after_save = {
				-- 	lsp_format = "fallback",
				-- },
				formatters = {
					goimports = {
						command = "goimports",
						args = { "-local", "gitlab.com/hmajid2301,git.curve.tools,go.curve.tools" },
					},
					yamlfmt = {
						args = { "-formatter", "retain_line_breaks_single=true" },
					},
				},
				formatters_by_ft = {
					css = { "prettierd" },
					go = { "gofmt", "goimports" },
					lua = { "stylua" },
					templ = { "rustywind", "templ" },
					html = { "htmlbeautifier", "rustywind" },
					nix = { "nixfmt" },
					markdown = { "trim_newlines", "trim_whitespace" },
					python = { "isort", "black" },
					javascript = { "prettierd" },
					typescript = { "prettierd" },
					terraform = { "terraform_fmt" },
					sql = { "sqlfluff" },
					svelte = { "prettierd" },
					yaml = { "yamlfmt" },
				},
			})
		end,
	},
})

vim.api.nvim_create_user_command("FormatDisable", function(args)
	if args.bang then
		-- FormatDisable! will disable formatting just for this buffer
		vim.b.disable_autoformat = true
	else
		vim.g.disable_autoformat = true
	end
end, {
	desc = "Disable autoformat-on-save",
	bang = true,
})
vim.api.nvim_create_user_command("FormatEnable", function()
	vim.b.disable_autoformat = false
	vim.g.disable_autoformat = false
end, {
	desc = "Re-enable autoformat-on-save",
})
