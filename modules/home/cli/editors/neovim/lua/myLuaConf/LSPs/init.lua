local servers = {}
if nixCats("neonixdev") then
	servers.lua_ls = {
		Lua = {
			formatters = {
				ignoreComments = true,
			},
			signatureHelp = { enabled = true },
			diagnostics = {
				globals = { "nixCats" },
				disable = { "missing-fields" },
			},
		},
		telemetry = { enabled = false },
		filetypes = { "lua" },
	}

	if require("nixCatsUtils").isNixCats then
		servers.nixd = {
			nixd = {
				nixpkgs = {
					expr = [[import (builtins.getFlake "]] .. nixCats.extra("nixdExtras.nixpkgs") .. [[") { }   ]],
				},
				formatting = {
					command = { "nixfmt" },
				},
				diagnostic = {
					suppress = {
						"sema-escaping-with",
					},
				},
			},
		}
		-- TODO:
		-- If you integrated with your system flake,
		-- you should pass inputs.self as nixdExtras.flake-path
		-- that way it will ALWAYS work, regardless
		-- of where your config actually was.
		-- otherwise flake-path could be an absolute path to your system flake, or nil or false
		if nixCats.extra("nixdExtras.flake-path") then
			local flakePath = nixCats.extra("nixdExtras.flake-path")
			if nixCats.extra("nixdExtras.systemCFGname") then
				-- (builtins.getFlake "<path_to_system_flake>").nixosConfigurations."<name>".options
				servers.nixd.nixd.options.nixos = {
					expr = [[(builtins.getFlake "]] .. flakePath .. [[").nixosConfigurations."]] .. nixCats.extra(
						"nixdExtras.systemCFGname"
					) .. [[".options]],
				}
			end
			if nixCats.extra("nixdExtras.homeCFGname") then
				-- (builtins.getFlake "<path_to_system_flake>").homeConfigurations."<name>".options
				servers.nixd.nixd.options["home-manager"] = {
					expr = [[(builtins.getFlake "]] .. flakePath .. [[").homeConfigurations."]] .. nixCats.extra(
						"nixdExtras.homeCFGname"
					) .. [[".options]],
				}
			end
		end
	else
		servers.rnix = {}
		servers.nil_ls = {}
	end
end

-- This is this flake's version of what kickstarter has set up for mason handlers.
-- This is a convenience function that calls lspconfig on the lsps we downloaded via nix
-- This will not download your lsp. Nix does that.

--  Add any additional override configuration in the following tables. They will be passed to
--  the `settings` field of the server config. You must look up that documentation yourself.
--  All of them are listed in https://github.com/neovim/nvim-lspconfig/blob/master/doc/server_configurations.md
--
--  If you want to override the default filetypes that your language server will attach to you can
--  define the property 'filetypes' to the map in question.
--  You may do the same thing with cmd

servers.cssls = {}
servers.dockerls = {}
servers.jsonls = {}
servers.docker_compose_language_service = {}
servers.pyright = {}
servers.marksman = {}
servers.ts_ls = {}
servers.tailwindcss = {}
servers.terraformls = {}
servers.taplo = {}
servers.yamlls = {}

servers.html = {
	filetypes = { "html", "templ" },
	html = {
		format = {
			wrapLineLength = 120,
			wrapAttributes = "auto",
		},
		hover = {
			documentation = true,
			references = true,
		},
	},
}
servers.sqls = {
	sqls = {
		connections = {
			{
				driver = "postgresql",
				dataSourceName = "host=127.0.0.1 port=5432 user=postgres password=postgres dbname=postgres sslmode=disable",
			},
		},
	},
}

servers.gopls = {
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
}

if not require("nixCatsUtils").isNixCats and nixCats("lspDebugMode") then
	vim.lsp.set_log_level("debug")
end

vim.api.nvim_create_autocmd("LspAttach", {
	group = vim.api.nvim_create_augroup("nixCats-lsp-attach", { clear = true }),
	callback = function(event)
		require("myLuaConf.LSPs.caps-on_attach").on_attach(vim.lsp.get_client_by_id(event.data.client_id), event.buf)
	end,
})

require("lze").load({
	{
		"nvim-lspconfig",
		for_cat = "general.always",
		event = "FileType",
		load = (require("nixCatsUtils").isNixCats and vim.cmd.packadd) or function(name)
			vim.cmd.packadd(name)
			vim.cmd.packadd("mason.nvim")
			vim.cmd.packadd("mason-lspconfig.nvim")
		end,
		after = function(plugin)
			if require("nixCatsUtils").isNixCats then
				for server_name, cfg in pairs(servers) do
					require("lspconfig")[server_name].setup({
						capabilities = require("myLuaConf.LSPs.caps-on_attach").get_capabilities(server_name),
						-- this line is interchangeable with the above LspAttach autocommand
						-- on_attach = require('myLuaConf.LSPs.caps-on_attach').on_attach,
						settings = cfg,
						filetypes = (cfg or {}).filetypes,
						cmd = (cfg or {}).cmd,
						root_pattern = (cfg or {}).root_pattern,
					})
				end
			else
				require("mason").setup()
				local mason_lspconfig = require("mason-lspconfig")
				mason_lspconfig.setup({
					ensure_installed = vim.tbl_keys(servers),
				})
				mason_lspconfig.setup_handlers({
					function(server_name)
						require("lspconfig")[server_name].setup({
							capabilities = require("myLuaConf.LSPs.caps-on_attach").get_capabilities(server_name),
							-- this line is interchangeable with the above LspAttach autocommand
							-- on_attach = require('myLuaConf.LSPs.caps-on_attach').on_attach,
							settings = servers[server_name],
							filetypes = (servers[server_name] or {}).filetypes,
						})
					end,
				})
			end
		end,
	},
})