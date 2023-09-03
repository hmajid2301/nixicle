{pkgs, ...}: {
  imports = [
    ./coding/cmp.nix
  ];

  programs.nixvim = {
    extraPlugins = with pkgs.vimPlugins; [
      friendly-snippets
      nvim-surround
    ];

    extraConfigLua =
      # lua
      ''
        -- nvim-ufo
        local capabilities = vim.lsp.protocol.make_client_capabilities()
        capabilities.textDocument.foldingRange = {
        		dynamicRegistration = false,
        		lineFoldingOnly = true
        }
        local language_servers = require("lspconfig").util.available_servers()
        for _, ls in ipairs(language_servers) do
        		require('lspconfig')[ls].setup({
        				capabilities = capabilities
        		})
        end
        require('ufo').setup()

        -- autopairs
        local cmp_autopairs = require('nvim-autopairs.completion.cmp')
        local cmp = require('cmp')
        cmp.event:on('confirm_done', cmp_autopairs.on_confirm_done())

        require("which-key").register({
          ["<leader>s"] = { name = "+surround" },
          ["<leader>u"] = { name = "+fold" },
        })

        require("luasnip.loaders.from_vscode").lazy_load()
        require("nvim-surround").setup()
      '';

    maps = {
      normal = {
        "<leader>uR" = {
          action =
            # lua
            ''
              function()
              	require("ufo").openAllFolds
              end
            '';
          desc = "Open all folds";
        };
        "<leader>uM" = {
          action =
            # lua
            ''
              function()
              	require("ufo").closeAllFolds
              end
            '';
          desc = "Close all folds";
        };
      };
    };

    plugins = {
      luasnip = {
        enable = true;
      };

      nvim-ufo = {
        enable = true;
      };

      nvim-autopairs = {
        enable = true;
        disabledFiletypes = ["TelescopePrompt" "vim"];
      };

      comment-nvim = {
        enable = true;
      };
    };
  };
}
