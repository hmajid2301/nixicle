local catUtils = require("nixCatsUtils")
if catUtils.isNixCats and nixCats("lspDebugMode") then
	vim.lsp.set_log_level("debug")
end

-- NOTE: This file uses lzextras.lsp handler https://github.com/BirdeeHub/lzextras?tab=readme-ov-file#lsp-handler
-- This is a slightly more performant fallback function
-- for when you don't provide a filetype to trigger on yourself.
-- nixCats gives us the paths, which is faster than searching the rtp!
local old_ft_fallback = require("lze").h.lsp.get_ft_fallback()
require("lze").h.lsp.set_ft_fallback(function(name)
	local lspcfg = nixCats.pawsible({ "allPlugins", "opt", "nvim-lspconfig" })
		or nixCats.pawsible({ "allPlugins", "start", "nvim-lspconfig" })
	if lspcfg then
		local ok, cfg = pcall(dofile, lspcfg .. "/lsp/" .. name .. ".lua")
		if not ok then
			ok, cfg = pcall(dofile, lspcfg .. "/lua/lspconfig/configs/" .. name .. ".lua")
		end
		return (ok and cfg or {}).filetypes or {}
	else
		return old_ft_fallback(name)
	end
end)

vim.filetype.add({ extension = { templ = "templ" } })

require("lze").load({
	{
		"nvim-lspconfig",
		for_cat = "general.core",
		on_require = { "lspconfig" },
		-- NOTE: define a function for lsp,
		-- and it will run for all specs with type(plugin.lsp) == table
		-- when their filetype trigger loads them
		lsp = function(plugin)
			vim.lsp.config(plugin.name, plugin.lsp or {})
			vim.lsp.enable(plugin.name)
		end,
		before = function(_)
			vim.lsp.config("*", {
				on_attach = require("config.LSPs.on_attach"),
			})
		end,
	},
	{
		"mason.nvim",
		enabled = not catUtils.isNixCats,
		dep_of = { "nvim-lspconfig" },
		load = function(name)
			vim.cmd.packadd(name)
			vim.cmd.packadd("mason-lspconfig.nvim")
			require("mason").setup()
			require("mason-lspconfig").setup({ automatic_installation = true })
		end,
	},
	{
		"lazydev.nvim",
		for_cat = "neonixdev",
		cmd = { "LazyDev" },
		ft = "lua",
		after = function(_)
			require("lazydev").setup({
				library = {
					{ words = { "nixCats" }, path = (nixCats.nixCatsPath or "") .. "/lua" },
				},
			})
		end,
	},
	{
		"lua_ls",
		enabled = nixCats("lua") or nixCats("neonixdev"),
		lsp = {
			filetypes = { "lua" },
			settings = {
				Lua = {
					runtime = { version = "LuaJIT" },
					formatters = { ignoreComments = true },
					signatureHelp = { enabled = true },
					diagnostics = {
						globals = { "nixCats", "vim" },
						disable = { "missing-fields" },
					},
					library = {
						vim.env.VIMRUNTIME, -- Neovim runtime files
						-- Add other Lua paths if needed:
						-- "${3rd}/luv/library",
						-- "${3rd}/busted/library",
					},
					workspace = {
						checkThirdParty = false,
					},
					telemetry = { enabled = false },
				},
			},
		},
	},
	{
		"gopls",
		for_cat = "go",
		lsp = {
			settings = {
				gopls = {
					buildFlags = { "-tags=dev,unit,integration,e2e,bdd,dind" },
					staticcheck = true,
					directoryFilters = { "-.git", "-.vscode", "-.idea", "-.vscode-test", "-node_modules" },
					semanticTokens = true,
					codelenses = {
						gc_details = false,
						generate = true,
						regenerate_cgo = true,
						run_govulncheck = true,
						test = true,
						tidy = true,
						upgrade_dependency = true,
						vendor = true,
					},
					hints = {
						assignVariableTypes = false,
						compositeLiteralFields = false,
						compositeLiteralTypes = false,
						constantValues = true,
						functionTypeParameters = true,
						parameterNames = true,
						rangeVariableTypes = false,
					},
					analyses = {
						assign = true,
						bools = true,
						defers = true,
						deprecated = true,
						tests = true,
						nilness = true,
						httpresponse = true,
						unmarshal = true,
						unusedparams = true,
						unusedwrite = true,
						useany = true,
					},
				},
			},
		},
	},
	{
		"rnix",
		enabled = not catUtils.isNixCats,
		lsp = { filetypes = { "nix" } },
	},
	{
		"nil_ls",
		enabled = not catUtils.isNixCats,
		lsp = { filetypes = { "nix" } },
	},
	{
		"nixd",
		enabled = catUtils.isNixCats and (nixCats("nix") or nixCats("neonixdev")),
		lsp = {
			filetypes = { "nix" },
			settings = {
				nixd = {
					nixpkgs = {
						expr = [[import (builtins.getFlake "]] .. nixCats.extra("nixdExtras.nixpkgs") .. [[") { }]],
					},
					formatting = { command = { "nixfmt" } },
					options = {
						nixos = { expr = nixCats.extra("nixdExtras.nixos_options") },
						["home-manager"] = { expr = nixCats.extra("nixdExtras.home_manager_options") },
					},
					diagnostic = { suppress = { "sema-escaping-with" } },
				},
			},
		},
	},
	{ "cssls", lsp = {} },
	{ "dockerls", lsp = {} },
	{ "docker_compose_language_service", lsp = {} },
	{ "pyright", lsp = {} },
	{ "marksman", lsp = {} },
	{ "ts_ls", lsp = {} },
	{ "svelte", lsp = {} },
	{ "terraformls", lsp = {
		cmd = { "terraform-lsp", "serve" },
	} },
	{ "taplo", lsp = {} },
	{
		"jsonls",
		lsp = {
			settings = {
				json = {
					schemas = require("schemastore").json.schemas(),
					validate = { enable = true },
				},
			},
		},
	},
	{
		"yamlls",
		lsp = {},
	},
	{
		"tailwindcss",
		lsp = {},
	},
	{
		"html",
		lsp = {},
	},
	-- {
	-- 	"htmx",
	-- 	lsp = {},
	-- },
	{
		"templ",
		lsp = {},
	},
	{
		"sqls",
		lsp = {
			filetypes = { "sql" },
			settings = {
				sqls = {
					connections = {
						{
							driver = "postgresql",
							dataSourceName = "host=127.0.0.1 port=5432 user=postgres password=postgres dbname=postgres sslmode=disable",
						},
					},
				},
			},
			on_attach = function(client, bufnr)
				client.server_capabilities.documentFormattingProvider = false
				client.server_capabilities.documentRangeFormattingProvider = false

				-- -- Preserve default SQLs functionality
				-- require("sqls").on_attach(client, bufnr)
			end,
		},
	},
})
