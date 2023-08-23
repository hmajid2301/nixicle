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
        })

        require("luasnip.loaders.from_vscode").lazy_load()

        require("nvim-surround").setup({
          keymaps = {
            normal = "<leader>sa",
            normal_cur = "<leader>sA",
            visual = "<leader>sv",
            visual_line = "<leader>sV",
            delete = "<leader>sd",
            change = "<leader>sc",
            change_line = "<leader>sC",
          },
        })
      '';

    maps = {
      normal = {
        "<leader>zR" = {
          action =
            # lua
            ''
              function()
              	require("ufo").openAllFolds
              end
            '';
          desc = "Open all folds";
        };
        "<leader>zM" = {
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

    options = {
      foldcolumn = "1";
      foldlevel = 99;
      foldlevelstart = 99;
      foldenable = true;
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
