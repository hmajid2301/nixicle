{pkgs, ...}: {
  programs.nixvim = {
    keymaps = [
      {
        action = "<cmd>lua vim.lsp.buf.code_action()<CR>";
        key = "<leader>ca";
        mode = ["n" "v"];
        options = {
          desc = "Code Actions";
        };
      }
      {
        action = "<cmd>LspRestart<CR>";
        key = "<leader>lR";
        mode = ["n"];
        options = {
          desc = "Restart LSP";
        };
      }
      {
        action = "<cmd>Telescope lsp_references<CR>";
        key = "<leader>gr";
        mode = ["n"];
        options = {
          desc = "LSP References";
        };
      }
    ];

    plugins = {
      lsp = {
        enable = true;

        keymaps = {
          diagnostic = {
            "]d" = "goto_next";
            "[d" = "goto_prev";
          };
          lspBuf = {
            K = "hover";
            gD = "declaration";
            # gr = "references";
            gd = "definition";
            gi = "implementation";
            gt = "type_definition";
            "<leader>cr" = {
              action = "rename";
              desc = "Rename";
            };
          };
        };
      };

      conform-nvim = {
        enable = true;
        settings = {
          format_on_save = {
            lsp_fallback = true;
            timeout_ms = 500;
          };
        };
      };

      lint = {
        enable = true;
      };
    };

    extraConfigLua =
      # lua
      ''
        vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(vim.lsp.handlers.hover, {
        	border = "rounded",
        })

        vim.api.nvim_create_autocmd({ "BufWritePost" }, {
        	callback = function()
        		require("lint").try_lint()
        	end,
        })
      '';
  };
}
