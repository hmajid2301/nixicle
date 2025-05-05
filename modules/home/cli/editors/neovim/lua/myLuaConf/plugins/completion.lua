local function faster_get_path(name)
	local path = vim.tbl_get(package.loaded, "nixCats", "pawsible", "allPlugins", "opt", name)
	if path then
		vim.cmd.packadd(name)
		return path
	end
	return nil
end

local load_w_after_plugin = require("lzextras").make_load_with_afters({ "plugin" }, faster_get_path)

return {
	{
		"cmp_dbee",
		for_cat = "general.cmp",
		on_plugin = { "blink.cmp" },
		load = load_w_after_plugin,
	},
	{
		"cmp-go-deep",
		for_cat = "general.cmp",
		on_plugin = { "blink.cmp" },
		load = load_w_after_plugin,
	},
	{
		"friendly-snippets",
		for_cat = "general.cmp",
		dep_of = { "blink.cmp" },
	},
	{
		"lspkind.nvim",
		for_cat = "general.cmp",
		dep_of = { "blink.cmp" },
		load = load_w_after_plugin,
	},
	{
		"luasnip",
		for_cat = "general.cmp",
		dep_of = { "blink.cmp" },
		after = function()
			local luasnip = require("luasnip")
			require("luasnip.loaders.from_vscode").lazy_load()
			luasnip.config.setup({})

			require("myLuaConf.plugins.snippets.go").create_go_snippets()

			vim.keymap.set({ "i", "s" }, "<M-n>", function()
				if luasnip.choice_active() then
					luasnip.change_choice(1)
				end
			end)
		end,
	},
	{
		"blink.cmp",
		for_cat = "general.cmp",
		event = { "DeferredUIEnter" },
		on_require = { "cmp" },
		load = function(name)
			vim.cmd.packadd(name)
			vim.cmd.packadd("blink.compat")
			vim.cmd.packadd("blink-ripgrep")
			vim.cmd.packadd("snacks.nvim")
		end,
		after = function()
			require("blink-cmp").setup({
				sources = {
					default = { "lsp", "buffer", "snippets", "path" },
					per_filetype = {
						sql = { "buffer", "cmp-dbee", "snippets" },
						-- go = { "go_deep" }
					},
					providers = {
						ripgrep = { module = "blink-ripgrep", name = "Ripgrep" },
						["cmp-dbee"] = { name = "cmp-dbee", module = "blink.compat.source" },
						-- ["go_deep"] = { name = "go_deep", module = "blink.compat.source" },
					},
				},
				keymap = {
					preset = "enter",
					["<Tab>"] = { "select_next", "fallback" },
					["<S-Tab>"] = { "select_prev", "fallback" },
					["<C-j>"] = { "select_next", "fallback_to_mappings" },
					["<C-k>"] = { "select_prev", "fallback_to_mappings" },
				},
				snippets = { preset = "luasnip" },
				signature = { enabled = true },
				cmdline = {
					keymap = {
						["<cr>"] = {
							function(cmp)
								return cmp.accept({
									callback = function()
										vim.api.nvim_feedkeys("\n", "n", true)
									end,
								})
							end,
							"fallback",
						},
						["<Tab>"] = { "select_next" },
						["<S-Tab>"] = { "select_prev" },
						["<C-e>"] = { "cancel" },
					},
					completion = { menu = { auto_show = true } },
				},
				completion = {
					menu = {
						border = "single",
						auto_show = function(ctx)
							return ctx.mode ~= "cmdline" and not vim.tbl_contains({ "/", "?" }, vim.fn.getcmdtype())
						end,
						draw = {
							treesitter = { "lsp" },
							columns = {
								{ "label", "label_description" },
								{ "kind_icon", gap = 2, "kind" },
							},
						},
					},
					list = { selection = { preselect = false, auto_insert = true } },
					documentation = {
						auto_show = true,
						auto_show_delay_ms = 200,
						window = { border = "rounded" },
					},
				},
			})
		end,
	},
}
