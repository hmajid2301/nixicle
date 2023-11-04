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

    plugins.which-key.registrations = {
      "<leader>c" = "+code";
      "g" = "+goto";
      "]" = "+next";
      "[" = "+prev";
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
          "<leader>ca" = { action = "code_action"; desc = "Show Code Actions"; };
        };
      };
    };

    extraPlugins = with pkgs.vimPlugins; [
      conform-nvim
      nvim-lint
    ];

    extraConfigLua =
      ''
        local lsp = vim.lsp
        lsp.handlers["textDocument/hover"] = lsp.with(vim.lsp.handlers.hover, {
        	border = "rounded",
        })

        require("conform").setup({})

        vim.api.nvim_create_autocmd("BufWritePre", {
        	pattern = "*",
        	callback = function(args)
        		require("conform").format({ bufnr = args.buf })
        	end,
        })

        require('lint').linters_by_ft = {}

        vim.api.nvim_create_autocmd({ "BufWritePost" }, {
        	callback = function()
        		require("lint").try_lint()
        	end,
        })
      '';
  };
}
