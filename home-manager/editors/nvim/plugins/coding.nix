{ pkgs, ... }: {
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

        require("luasnip.loaders.from_vscode").lazy_load()
        require("nvim-surround").setup()
      '';

    keymaps = [
      {
        key = "<leader>uR";
        action =
          # lua
          ''
            function()
            	require("ufo").openAllFolds
            end
          '';
        lua = true;
        options = {
          desc = "Open all folds";
        };
        mode = [
          "n"
        ];
      }
      {
        key = "<leader>uM";
        action =
          # lua
          ''
            function()
            	require("ufo").closeAllFolds
            end
          '';
        lua = true;
        options = {
          desc = "Close all folds";
        };
        mode = [
          "n"
        ];
      }
    ];

    plugins = {
      which-key.registrations = {
        "u" = "+fold";
      };

      luasnip = {
        enable = true;
      };

      nvim-ufo = {
        enable = true;
      };

      nvim-autopairs = {
        enable = true;
        disabledFiletypes = [ "TelescopePrompt" "vim" ];
      };

      comment-nvim = {
        enable = true;
      };
    };
  };
}
