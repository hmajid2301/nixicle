local catUtils = require("nixCatsUtils")
if catUtils.isNixCats and nixCats("lspDebugMode") then
	vim.lsp.set_log_level("debug")
end

require("lze").load({
	-- Existing configurations...
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
	-- New LSP configurations added here
	{ "cssls", lsp = {} },
	{ "dockerls", lsp = {} },
	{ "jsonls", lsp = {} },
	{ "docker_compose_language_service", lsp = {} },
	{ "pyright", lsp = {} },
	{ "marksman", lsp = {} },
	{ "ts_ls", lsp = {} },
	{
		"tailwindcss",
		lsp = {
			filetypes = { "html", "templ" },
			settings = {
				includedLanguages = {
					templ = "html",
				},
			},
		},
	},
	{ "templ", lsp = {} },
	{ "terraformls", lsp = {} },
	{ "taplo", lsp = {} },
	{ "yamlls", lsp = {} },
	{
		"htmx",
		lsp = {
			filetypes = { "html", "templ" },
		},
	},
	-- {
	-- 	"html",
	-- 	lsp = {
	-- 		filetypes = { "html", "templ" },
	-- 		settings = {
	-- 			html = {
	-- 				format = {
	-- 					wrapLineLength = 120,
	-- 					wrapAttributes = "auto",
	-- 				},
	-- 				hover = {
	-- 					documentation = true,
	-- 					references = true,
	-- 				},
	-- 			},
	-- 		},
	-- 	},
	-- },
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
		},
	},
})
--
-- local servers = {}
-- if nixCats("neonixdev") then
-- 	servers.lua_ls = {
-- 		Lua = {
-- 			formatters = {
-- 				ignoreComments = true,
-- 			},
-- 			signatureHelp = { enabled = true },
-- 			diagnostics = {
-- 				globals = { "nixCats" },
-- 				disable = { "missing-fields" },
-- 			},
-- 		},
-- 		telemetry = { enabled = false },
-- 		filetypes = { "lua" },
-- 	}
--
-- 	if require("nixCatsUtils").isNixCats then
-- 		servers.nixd = {
-- 			nixd = {
-- 				nixpkgs = {
-- 					expr = [[import (builtins.getFlake "]] .. nixCats.extra("nixdExtras.nixpkgs") .. [[") { }   ]],
-- 				},
-- 				formatting = {
-- 					command = { "nixfmt" },
-- 				},
-- 				diagnostic = {
-- 					suppress = {
-- 						"sema-escaping-with",
-- 					},
-- 				},
-- 			},
-- 		}
-- 		-- TODO:
-- 		-- If you integrated with your system flake,
-- 		-- you should pass inputs.self as nixdExtras.flake-path
-- 		-- that way it will ALWAYS work, regardless
-- 		-- of where your config actually was.
-- 		-- otherwise flake-path could be an absolute path to your system flake, or nil or false
-- 		if nixCats.extra("nixdExtras.flake-path") then
-- 			local flakePath = nixCats.extra("nixdExtras.flake-path")
-- 			if nixCats.extra("nixdExtras.systemCFGname") then
-- 				-- (builtins.getFlake "<path_to_system_flake>").nixosConfigurations."<name>".options
-- 				servers.nixd.nixd.options.nixos = {
-- 					expr = [[(builtins.getFlake "]] .. flakePath .. [[").nixosConfigurations."]] .. nixCats.extra(
-- 						"nixdExtras.systemCFGname"
-- 					) .. [[".options]],
-- 				}
-- 			end
-- 			if nixCats.extra("nixdExtras.homeCFGname") then
-- 				-- (builtins.getFlake "<path_to_system_flake>").homeConfigurations."<name>".options
-- 				servers.nixd.nixd.options["home-manager"] = {
-- 					expr = [[(builtins.getFlake "]] .. flakePath .. [[").homeConfigurations."]] .. nixCats.extra(
-- 						"nixdExtras.homeCFGname"
-- 					) .. [[".options]],
-- 				}
-- 			end
-- 		end
-- 	else
-- 		servers.rnix = {}
-- 		servers.nil_ls = {}
-- 	end
-- end
--
-- -- This is this flake's version of what kickstarter has set up for mason handlers.
-- -- This is a convenience function that calls lspconfig on the lsps we downloaded via nix
-- -- This will not download your lsp. Nix does that.
--
-- --  Add any additional override configuration in the following tables. They will be passed to
-- --  the `settings` field of the server config. You must look up that documentation yourself.
-- --  All of them are listed in https://github.com/neovim/nvim-lspconfig/blob/master/doc/server_configurations.md
-- --
-- --  If you want to override the default filetypes that your language server will attach to you can
-- --  define the property 'filetypes' to the map in question.
-- --  You may do the same thing with cmd
--
-- servers.cssls = {}
-- servers.dockerls = {}
-- servers.jsonls = {}
-- servers.docker_compose_language_service = {}
-- servers.pyright = {}
-- servers.marksman = {}
-- servers.ts_ls = {}
-- servers.tailwindcss = {}
-- servers.terraformls = {}
-- servers.taplo = {}
-- servers.yamlls = {}
--
-- servers.html = {
-- 	filetypes = { "html", "templ" },
-- 	html = {
-- 		format = {
-- 			wrapLineLength = 120,
-- 			wrapAttributes = "auto",
-- 		},
-- 		hover = {
-- 			documentation = true,
-- 			references = true,
-- 		},
-- 	},
-- }
-- servers.sqls = {
-- 	sqls = {
-- 		connections = {
-- 			{
-- 				driver = "postgresql",
-- 				dataSourceName = "host=127.0.0.1 port=5432 user=postgres password=postgres dbname=postgres sslmode=disable",
-- 			},
-- 		},
-- 	},
-- }
--
-- servers.gopls = {
-- 	gopls = {
-- 		buildFlags = { "-tags=unit,integration,e2e,bdd,dind" },
-- 		staticcheck = true,
-- 		directoryFilters = { "-.git", "-.vscode", "-.idea", "-.vscode-test", "-node_modules" },
-- 		semanticTokens = true,
-- 		codelenses = {
-- 			gc_details = false,
-- 			generate = true,
-- 			regenerate_cgo = true,
-- 			run_govulncheck = true,
-- 			test = true,
-- 			tidy = true,
-- 			upgrade_dependency = true,
-- 			vendor = true,
-- 		},
-- 		hints = {
-- 			assignVariableTypes = false,
-- 			compositeLiteralFields = false,
-- 			compositeLiteralTypes = false,
-- 			constantValues = true,
-- 			functionTypeParameters = true,
-- 			parameterNames = true,
-- 			rangeVariableTypes = false,
-- 		},
-- 		analyses = {
-- 			assign = true,
-- 			bools = true,
-- 			defers = true,
-- 			deprecated = true,
-- 			tests = true,
-- 			nilness = true,
-- 			httpresponse = true,
-- 			unmarshal = true,
-- 			unusedparams = true,
-- 			unusedwrite = true,
-- 			useany = true,
-- 		},
-- 	},
-- }
