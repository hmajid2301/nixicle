{ pkgs, ... }: {
  programs.nixvim = {
    maps.normalVisualOp = {
      "<leader>ca" = {
        action =
          # lua
          ''
            function()
            	return vim.lsp.buf.code_action
            end
          '';
        desc = "Show code actions";
      };
    };
    plugins.lsp = {
      enable = true;
      keymaps = {
        diagnostic = {
          "]d" = "goto_next";
          "[d" = "goto_prev";
        };
        lspBuf = {
          K = "hover";
          gD = "declaration";
          gr = "references";
          gd = "definition";
          gi = "implementation";
          gt = "type_definition";
          "<leader>cr" = { action = "rename"; desc = "Rename"; };
        };
      };
    };

    # TODO: move to nixvim
    extraPlugins = with pkgs.vimPlugins; [ null-ls-nvim ];
    extraConfigLua =
      ''
        require("which-key").register({
        	["<leader>c"] = { name = "+code" },
        	["g"] = { name = "+goto" },
        	["]"] = { name = "+next" },
        	["["] = { name = "+prev" },
        })

        require("null-ls").setup({
          sources = {
            -- lua
            require("null-ls").builtins.formatting.stylua.with({ command = "${pkgs.stylua}/bin/stylua" }),
            require("null-ls").builtins.formatting.fish_indent.with({ command = "${pkgs.fish}/bin/fish_indent" }),

            -- Nix
            require("null-ls").builtins.formatting.nixpkgs_fmt.with({ command = "${pkgs.nixpkgs-fmt}/bin/nixpkgs-fmt" }),
            require("null-ls").builtins.diagnostics.deadnix.with({ command = "${pkgs.deadnix}/bin/deadnix" }),
            require("null-ls").builtins.code_actions.statix.with({ command = "${pkgs.statix}/bin/statix" }),

            -- Go
            require("null-ls").builtins.formatting.goimports.with({ command = "${pkgs.gotools}/bin/goimports" }),
            require("null-ls").builtins.formatting.gofumpt.with({ command = "${pkgs.gofumpt}/bin/gofumpt" }),
            require("null-ls").builtins.diagnostics.golangci_lint.with({ command = "${pkgs.golangci-lint}/bin/golangci-lint" }),
            require("null-ls").builtins.code_actions.gomodifytags.with({ command = "${pkgs.gomodifytags}/bin/gomodifytags" }),
            require("null-ls").builtins.code_actions.impl.with({ command = "${pkgs.impl}/bin/impl" }),
          },

          on_attach = function(client, bufnr)
            if client.supports_method("textDocument/formatting") then
              -- Auto-format on save
              vim.api.nvim_clear_autocmds({ group = augroup, buffer = bufnr })
              vim.api.nvim_create_autocmd("BufWritePre", {
                group = augroup,
                buffer = bufnr,
                callback = function()
                  vim.lsp.buf.format({ bufnr = bufnr })
                end,
              })
              -- Use internal formatting for bindings like gq.
              vim.api.nvim_create_autocmd("LspAttach", {
                callback = function(args)
                  vim.bo[args.buf].formatexpr = nil
                end,
              })
            end
          end,
        })
      '';
  };
}
