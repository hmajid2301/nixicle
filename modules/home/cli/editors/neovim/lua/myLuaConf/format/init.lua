require("lze").load({
	{
		"conform.nvim",
		for_cat = "format",
		-- cmd = { "" },
		-- event = "",
		-- ft = "",
		-- colorscheme = "",
		after = function(plugin)
			local conform = require("conform")

			conform.setup({
				format_on_save = {
					lsp_format = "fallback",
					timeout_ms = 500,
				},
				formatters = {
					goimports = {
						command = "goimports",
						args = { "-local", "gitlab.com/hmajid2301,git.curve.tools,go.curve.tools" },
					},
				},
				formatters_by_ft = {
					css = { "prettierd" },
					go = { "gofmt", "goimports" },
					lua = { "stylua" },
					-- TODO: fix these
					-- templ = { "rustywind" },
					-- html = { "htmlbeautifier", "rustywind" },
					nix = { "nixfmt" },
					python = { "isort", "black" },
					javascript = { "prettierd" },
					typescript = { "prettierd" },
					-- yaml = { "yamlfmt" },
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
