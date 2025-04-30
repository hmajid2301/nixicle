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
	-- CMP Plugins
	{
		"cmp-buffer",
		for_cat = "general.cmp",
		on_plugin = { "nvim-cmp" },
		load = load_w_after_plugin,
	},
	{
		"cmp-cmdline",
		for_cat = "general.cmp",
		on_plugin = { "nvim-cmp" },
		load = load_w_after_plugin,
	},
	{
		"cmp-cmdline-history",
		for_cat = "general.cmp",
		on_plugin = { "nvim-cmp" },
		load = load_w_after_plugin,
	},
	{
		"cmp-nvim-lsp",
		for_cat = "general.cmp",
		on_plugin = { "nvim-cmp" },
		dep_of = { "nvim-lspconfig" },
		load = load_w_after_plugin,
	},
	{
		"cmp-nvim-lsp-signature-help",
		for_cat = "general.cmp",
		on_plugin = { "nvim-cmp" },
		load = load_w_after_plugin,
	},
	{
		"cmp-nvim-lua",
		for_cat = "general.cmp",
		on_plugin = { "nvim-cmp" },
		load = load_w_after_plugin,
	},
	{
		"cmp-path",
		for_cat = "general.cmp",
		on_plugin = { "nvim-cmp" },
		load = load_w_after_plugin,
	},
	{
		"cmp_luasnip",
		for_cat = "general.cmp",
		on_plugin = { "nvim-cmp" },
		load = load_w_after_plugin,
	},
	{
		"cmp_dbee",
		for_cat = "general.cmp",
		on_plugin = { "nvim-cmp" },
		load = load_w_after_plugin,
	},
	{
		"cmp-go-deep",
		for_cat = "general.cmp",
		on_plugin = { "nvim-cmp" },
		load = load_w_after_plugin,
	},
	{
		"friendly-snippets",
		for_cat = "general.cmp",
		dep_of = { "nvim-cmp" },
	},
	{
		"lspkind.nvim",
		for_cat = "general.cmp",
		dep_of = { "nvim-cmp" },
		load = load_w_after_plugin,
	},
	{
		"luasnip",
		for_cat = "general.cmp",
		dep_of = { "nvim-cmp" },
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

	-- Main CMP Configuration
	{
		"nvim-cmp",
		for_cat = "general.cmp",
		event = { "DeferredUIEnter" },
		on_require = { "cmp" },
		after = function()
			local cmp = require("cmp")
			local luasnip = require("luasnip")
			local lspkind = require("lspkind")

			local options = {
				window = {
					completion = cmp.config.window.bordered({
						winhighlight = "FloatBorder:CmpBorder,Normal:CmpPmenu,CursorLine:CmpSel,Search:PmenuSel",
						scrollbar = false,
						side_padding = 1,
						col_offset = -4,
						border = {
							"╭",
							"─",
							"╮",
							"│",
							"╯",
							"─",
							"╰",
							"│",
						},
					}),
					documentation = cmp.config.window.bordered({
						side_padding = 1,
						border = {
							"╭",
							"─",
							"╮",
							"│",
							"╯",
							"─",
							"╰",
							"│",
						},
						winhighlight = "FloatBorder:CmpBorder,Normal:CmpPmenu,CursorLine:CmpSel,Search:PmenuSel",
					}),
				},
				formatting = {
					format = lspkind.cmp_format({
						mode = "symbol_text",
						preset = "default",
						menu = {
							nvim_lsp = "[LSP]",
							luasnip = "[Snippet]",
							buffer = "[Buffer]",
							path = "[Path]",
							nvim_lua = "[Lua]",
							cmp_dbee = "[DB]",
						},
						maxwidth = 60,
						ellipsis_char = "...",
					}),
				},
				snippet = {
					expand = function(args)
						luasnip.lsp_expand(args.body)
					end,
				},
				mapping = cmp.mapping.preset.insert({
					["<C-p>"] = cmp.mapping.scroll_docs(-4),
					["<C-n>"] = cmp.mapping.scroll_docs(4),
					["<C-j>"] = cmp.mapping.select_next_item(),
					["<C-k>"] = cmp.mapping.select_prev_item(),
					["<C-d>"] = cmp.mapping.scroll_docs(-4),
					["<C-f>"] = cmp.mapping.scroll_docs(4),
					["<C-e>"] = cmp.mapping.close(),
					["<C-Space>"] = cmp.mapping.complete({}),
					["<CR>"] = cmp.mapping.confirm({
						behavior = cmp.ConfirmBehavior.Replace,
						select = true,
					}),
					["<Tab>"] = cmp.mapping(function(fallback)
						if cmp.visible() then
							cmp.select_next_item()
						elseif luasnip.expand_or_locally_jumpable() then
							luasnip.expand_or_jump()
						else
							fallback()
						end
					end, { "i", "s" }),
					["<S-Tab>"] = cmp.mapping(function(fallback)
						if cmp.visible() then
							cmp.select_prev_item()
						elseif luasnip.locally_jumpable(-1) then
							luasnip.jump(-1)
						else
							fallback()
						end
					end, { "i", "s" }),
				}),
				sources = cmp.config.sources({
					{ name = "nvim_lsp" },
					{ name = "nvim_lsp_signature_help" },
					{ name = "go_deep" },
					{ name = "path" },
					{ name = "luasnip" },
					{ name = "buffer" },
				}),
				enabled = function()
					return vim.bo[0].buftype ~= "prompt"
				end,
				experimental = {
					native_menu = false,
					ghost_text = false,
				},
			}

			-- Setup highlight groups for margins
			vim.api.nvim_set_hl(0, "CmpItemKind", { bg = "NONE" })
			vim.api.nvim_set_hl(0, "CmpItemMenu", { fg = "#565f89", italic = true })

			cmp.setup(options)

			-- Filetype-specific configurations
			cmp.setup.filetype("lua", {
				sources = cmp.config.sources({
					{ name = "nvim_lua" },
					{ name = "nvim_lsp" },
					{ name = "nvim_lsp_signature_help" },
					{ name = "path" },
					{ name = "luasnip" },
					{ name = "buffer" },
				}),
			})

			cmp.setup.filetype("sql", {
				sources = cmp.config.sources({
					{ name = "cmp-dbee" },
					{ name = "buffer" },
					{ name = "luasnip" },
				}),
			})

			-- Cmdline configurations
			cmp.setup.cmdline({ "/", "?" }, {
				mapping = cmp.mapping.preset.cmdline(),
				sources = {
					{ name = "nvim_lsp_document_symbol" },
					{ name = "buffer" },
					{ name = "cmdline_history" },
				},
			})

			cmp.setup.cmdline(":", {
				mapping = cmp.mapping.preset.cmdline(),
				sources = cmp.config.sources({
					{ name = "cmdline" },
					{ name = "path" },
				}),
			})
		end,
	},
}
