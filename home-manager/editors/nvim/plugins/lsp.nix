{ pkgs, ... }: {
  programs.nixvim = {
    keymaps = [
      {
        action = "vim.lsp.buf.code_action";
        key = "<leader>ca";
        mode = [ "v" ];
        options = {
          desc = "Code Actions";
        };
      }
    ];

    plugins = {
      which-key.registrations = {
        "<leader>c" = "+code";
        "g" = "+goto";
        "]" = "+next";
        "[" = "+prev";
      };

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
            gr = "references";
            gd = "definition";
            gi = "implementation";
            gt = "type_definition";
            "<leader>cr" = { action = "rename"; desc = "Rename"; };
            "<leader>ca" = { action = "code_action"; desc = "Show Code Actions"; };
          };
        };
      };

      conform-nvim = {
        enable = true;
        formatOnSave = {
          lspFallback = true;
          timeoutMs = 500;
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
