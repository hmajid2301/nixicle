return {
	{
		"sidekick.nvim",
		for_cat = "ai",
		event = "DeferredUIEnter",
		after = function(plugin)
			require("sidekick").setup({
				nes = {
					enabled = false,
				},
				cli = {
					mux = {
						backend = "zellij",
						enabled = true,
					},
				},
			})
		end,
	},
	{
		"pi-nvim",
		for_cat = "ai",
		event = "DeferredUIEnter",
		opts = {
			context_format = "reference",
			send_behavior = "followUp",
			live_context = {
				enabled = true,
				debounce_ms = 150,
				include_buffer_text = false,
				max_buffer_bytes = 200000,
				max_selection_bytes = 50000,
			},
		},
		keys = {
			{ "<leader>Pa", ":Pi<CR>", mode = { "n", "v" }, desc = "Send to pi" },
			{ "<leader>Pp", ":PiSend<CR>", mode = "n", desc = "Type and send to pi" },
			{ "<leader>Pf", ":PiSendFile<CR>", mode = "n", desc = "Send file to pi" },
			{ "<leader>Ps", ":PiSendSelection<CR>", mode = "v", desc = "Send selection to pi" },
			{ "<leader>Pb", ":PiSendBuffer<CR>", mode = "n", desc = "Send buffer to pi" },
			{ "<leader>Pi", ":PiPing<CR>", mode = "n", desc = "Ping pi" },
		},
		after = function(_, opts)
			require("pi-nvim").setup(opts)
			-- pi-nvim maps `p` by default; restore yanky paste mappings.
			pcall(vim.keymap.del, "n", "p")
			pcall(vim.keymap.del, "v", "p")
			vim.keymap.set({ "n", "x" }, "p", "<Plug>(YankyPutAfter)", { desc = "Yanky put after" })
			-- Pi ↔ Neovim bidirectional edit bridge
			require("config.plugins.nvim-edit").setup()
		end,
	},
}
