-- OXY2DEV fancy hover and diagnostics
-- https://github.com/OXY2DEV/nvim

return {
	{
		after = function()
			-- Setup LSP hover
			local hover = require("scripts.lsp_hover")
			hover.setup({
				-- Add custom configurations per LSP if needed
				nixd = {
					condition = function(client_name)
						return client_name == "nixd"
					end,
					winopts = {
						footer_pos = "right",
						footer = {
							{ "  Nix ", "@keyword" },
						},
					},
				},
				gopls = {
					condition = function(client_name)
						return client_name == "gopls"
					end,
					winopts = {
						footer_pos = "right",
						footer = {
							{ "  Go ", "@function" },
						},
					},
				},
			})

			-- Setup fancy diagnostics
			local diagnostics = require("scripts.diagnostics")
			diagnostics.setup({
				keymap = "gD", -- Use gD for diagnostics (D might conflict)
			})
		end,
	},
}
