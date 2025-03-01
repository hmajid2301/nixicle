local catUtils = require("nixCatsUtils")
if catUtils.isNixCats and nixCats("lspDebugMode") then
	vim.lsp.set_log_level("debug")
end
-- this is how to use the lsp handler.
require("lze").load({
	{
		"nvim-lspconfig",
		for_cat = "general.core",
		-- the on require handler will be needed here if you want to use the
		-- fallback method of getting filetypes if you don't provide any
		on_require = { "lspconfig" },
		-- define a function to run over all type(plugin.lsp) == table
		-- when their filetype trigger loads them
		lsp = function(plugin)
			-- in this case, just extend some default arguments with the ones provided in the lsp table
			require("lspconfig")[plugin.name].setup(vim.tbl_extend("force", {
				capabilities = require("myLuaConf.LSPs.caps-on_attach").get_capabilities(plugin.name),
				on_attach = require("myLuaConf.LSPs.caps-on_attach").on_attach,
			}, plugin.lsp or {}))
		end,
	},
	{
		"mason.nvim",
		-- only run it when not on nix
		enabled = not catUtils.isNixCats,
		-- dep_of handler ensures we have mason-lspconfig set up before nvim-lspconfig
		dep_of = { "nvim-lspconfig" },
		load = function(name)
			vim.cmd.packadd(name)
			vim.cmd.packadd("mason-lspconfig.nvim")
			require("mason").setup()
			-- auto install will make it install servers when lspconfig is called on them.
			require("mason-lspconfig").setup({ automatic_installation = true })
		end,
	},
	{
		-- lazydev makes your lsp way better in your config without needing extra lsp configuration.
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
		-- name of the lsp
		"lua_ls",
		enabled = nixCats("lua") or nixCats("neonixdev"),
		-- provide a table containing filetypes,
		-- and then whatever your functions defined in the function type specs expect.
		-- in our case, it just expects the normal lspconfig setup options,
		-- but with a default on_attach and capabilities
		lsp = {
			-- if you provide the filetypes it doesn't ask lspconfig for the filetypes
			filetypes = { "lua" },
			settings = {
				Lua = {
					runtime = { version = "LuaJIT" },
					formatters = {
						ignoreComments = true,
					},
					signatureHelp = { enabled = true },
					diagnostics = {
						globals = { "nixCats", "vim" },
						disable = { "missing-fields" },
					},
					telemetry = { enabled = false },
				},
			},
		},
		-- also these are regular specs and you can use before and after and all the other normal fields
	},
	{
		"gopls",
		for_cat = "go",
		-- if you don't provide the filetypes it asks lspconfig for them
		lsp = {},
	},
	{
		"rnix",
		-- mason doesn't have nixd
		enabled = not catUtils.isNixCats,
		lsp = {
			filetypes = { "nix" },
		},
	},
	{
		"nil_ls",
		-- mason doesn't have nixd
		enabled = not catUtils.isNixCats,
		lsp = {
			filetypes = { "nix" },
		},
	},
	{
		"nixd",
		enabled = catUtils.isNixCats and (nixCats("nix") or nixCats("neonixdev")),
		lsp = {
			filetypes = { "nix" },
			settings = {
				nixd = {
					-- nixd requires some configuration in flake based configs.
					-- luckily, the nixCats plugin is here to pass whatever we need!
					-- we passed this in via the `extra` table in our packageDefinitions
					-- for additional configuration options, refer to:
					-- https://github.com/nix-community/nixd/blob/main/nixd/docs/configuration.md
					nixpkgs = {
						expr = [[import (builtins.getFlake "]] .. nixCats.extra("nixdExtras.nixpkgs") .. [[") { }   ]],
					},
					formatting = {
						command = { "nixfmt" },
					},
					options = {
						-- If you integrated with your system flake,
						-- you should use inputs.self as the path to your system flake
						-- that way it will ALWAYS work, regardless
						-- of where your config actually was.
						nixos = {
							-- ''(builtins.getFlake "${inputs.self}").nixosConfigurations.configname.options''
							expr = nixCats.extra("nixdExtras.nixos_options"),
						},
						-- If you have your config as a separate flake, inputs.self would be referring to the wrong flake.
						-- You can override the correct one into your package definition on import in your main configuration,
						-- or just put an absolute path to where it usually is and accept the impurity.
						["home-manager"] = {
							-- ''(builtins.getFlake "${inputs.self}").homeConfigurations.configname.options''
							expr = nixCats.extra("nixdExtras.home_manager_options"),
						},
					},
					diagnostic = {
						suppress = {
							"sema-escaping-with",
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
