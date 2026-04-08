local nixUtils = require("nix_utils")
if nixUtils.isNix and nixInfo(false, "lspDebugMode") then
	vim.lsp.set_log_level("debug")
end

local old_ft_fallback = require("lze").h.lsp.get_ft_fallback()
require("lze").h.lsp.set_ft_fallback(function(name)
	local lspcfg = nixInfo(nil, "plugins", "lazy", "nvim-lspconfig")
		or nixInfo(nil, "plugins", "start", "nvim-lspconfig")
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
		for_cat = "lsp-core",
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
		enabled = not nixUtils.isNix,
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
					-- Add vim type stubs
					{ words = { "vim" }, path = "${3rd}/luv/library" },
				},
			})
		end,
	},
	{
		"lua_ls",
		enabled = nixInfo(false, "settings", "cats", "lua") or nixInfo(false, "settings", "cats", "neonixdev"),
		lsp = {
			filetypes = { "lua" },
			settings = {
				Lua = {
					runtime = { version = "LuaJIT" },
					formatters = { ignoreComments = true },
					signatureHelp = { enabled = true },
					diagnostics = {
						globals = { "nixInfo", "vim", "Snacks" },
						disable = { "missing-fields", "undefined-global" },
						libraryFiles = "Disable",
					},
					runtime_diagnostics = {
						enable = false,
					},
					library = {
						vim.env.VIMRUNTIME,
						"${3rd}/luv/library",
					},
					workspace = {
						checkThirdParty = false,
						ignoreDir = { ".git" },
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
		enabled = not nixUtils.isNix,
		lsp = { filetypes = { "nix" } },
	},
	{
		"nil_ls",
		enabled = not nixUtils.isNix,
		lsp = { filetypes = { "nix" } },
	},
	{
		"nixd",
		enabled = nixUtils.isNix
			and (nixInfo(false, "settings", "cats", "nix") or nixInfo(false, "settings", "cats", "neonixdev")),
		lsp = {
			filetypes = { "nix" },
			settings = {
				nixd = {
					nixpkgs = {
						expr = nixInfo(nil, "nixdExtras", "nixpkgs"),
					},
					formatting = { command = { "nixfmt" } },
					options = {
						nixos = { expr = nixInfo(nil, "nixdExtras", "nixos_options") },
						["home-manager"] = { expr = nixInfo(nil, "nixdExtras", "home_manager_options") },
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
	{
		"harper_ls",
		lsp = {
			filetypes = { "markdown", "text" },
			settings = {
				["harper-ls"] = {
					linters = {
						spell_check = true,
						spelled_numbers = false,
						an_a = true,
						sentence_capitalization = true,
						unclosed_quotes = true,
						wrong_quotes = false,
						long_sentences = true,
						repeated_words = true,
						spaces = true,
						matcher = true,
					},
				},
			},
		},
	},
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
		lsp = {
			settings = {
				yaml = {
					schemas = {
						["https://taskfile.dev/schema.json"] = {
							"Taskfile.yml",
							"Taskfile.yaml",
							"tasks/*.yml",
							"tasks/*.yaml",
						},
					},
				},
			},
		},
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
