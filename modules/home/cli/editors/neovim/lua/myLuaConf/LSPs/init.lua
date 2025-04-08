local catUtils = require("nixCatsUtils")
if catUtils.isNixCats and nixCats("lspDebugMode") then
	vim.lsp.set_log_level("debug")
end

vim.filetype.add({ extension = { templ = "templ" } })

require("lze").load({
	{
		"nvim-lspconfig",
		for_cat = "general.core",
		on_require = { "lspconfig" },
		lsp = function(plugin)
			require("lspconfig")[plugin.name].setup(vim.tbl_extend("force", {
				capabilities = require("myLuaConf.LSPs.caps-on_attach").get_capabilities(plugin.name),
				on_attach = require("myLuaConf.LSPs.caps-on_attach").on_attach,
			}, plugin.lsp or {}))
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
					buildFlags = { "-tags=unit,integration,e2e,bdd,dind" },
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
		-- enabled = catUtils.isNixCats and (nixCats("nix") or nixCats("neonixdev")),
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
	-- New LSP configurations added here
	{ "cssls", lsp = {} },
	{ "dockerls", lsp = {} },
	{ "jsonls", lsp = {} },
	{ "docker_compose_language_service", lsp = {} },
	{ "pyright", lsp = {} },
	{ "marksman", lsp = {} },
	{ "ts_ls", lsp = {} },
	{ "terraformls", lsp = {} },
	-- { "taplo", lsp = {} },
	{ "yamlls", lsp = {} },
	{
		"tailwindcss",
		-- root_dir = function(fname)
		-- 	return vim.fs.dirname(vim.fs.find(".git", { path = fname, upward = true })[1])
		-- end,
		lsp = {
			filetypes = { "templ" },
			settings = {
				tailwindcss = {
					experimental = {
						-- classRegex = {
						-- 	"@?class\\(([^]*)\\)",
						-- 	"'([^']*)'",
						-- },
						configFile = {
							"static/css/tailwind.css",
						},
					},
					includeLanguages = {
						templ = "html",
					},
				},
			},
		},
	},
	-- TODO: work out how to enable
	-- {
	-- 	"html",
	-- 	lsp = {
	-- 	},
	-- },
	-- {
	-- 	"htmx",
	-- 	lsp = {},
	-- },
	{
		"templ",
		lsp = {
			filetypes = { "templ" },
		},
	},
	{
		"sqls",
		lsp = {
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
