{ pkgs, ... }: {
  imports = [
    ./editor/notes.nix
    ./editor/telescope.nix
    ./editor/trouble.nix
  ];

  programs.nixvim = {
    clipboard.providers.wl-copy.enable = true;
    keymaps = [
      {
        action = "<cmd>lua require('flash').jump()<cr>";
        key = "<leader>gls";
        options = {
          desc = "Run flash";
        };
        mode = [
          "n"
          "x"
        ];
      }
      {
        action = "<cmd>lua require('flash').treesitter()<cr>";
        key = "<leader>glt";
        options = {
          desc = "Run flash treesitter";
        };
        mode = [
          "n"
          "x"
        ];
      }
      {
        action = "<cmd>Telescope undo<cr>";
        key = "<leader>uu";
        options = {
          desc = "Show undo tree";
        };
        mode = [
          "n"
        ];
      }
      {
        action = "<cmd>Navbuddy<cr>";
        key = "<leader>nb";
        options = {
          desc = "Show navbuddy";
        };
        mode = [
          "n"
        ];
      }
      {
        action = "<cmd>lua require('spectre').open()<cr>";
        key = "<leader>sr";
        options = {
          desc = "Replace in file";
        };
        mode = [
          "n"
        ];
      }
    ];

    plugins = {
      auto-save = {
        enable = true;
				writeAllBuffers = true;
      };

      better-escape = {
        enable = true;
      };

      illuminate = {
        enable = true;
        delay = 200;
        underCursor = true;
        largeFileOverrides = {
          largeFileCutoff = 2000;
        };
      };

      oil = {
        enable = true;
        deleteToTrash = true;
      };

      flash = {
        enable = true;
      };

      navbuddy = {
        enable = true;
        lsp.autoAttach = true;
      };

      nvim-lightbulb = {
        enable = true;
        autocmd.enabled = true;
        statusText.enabled = true;
      };

      harpoon = {
        enable = true;
        enableTelescope = true;
        keymaps = {
          addFile = "<leader>ha";
          toggleQuickMenu = "<leader>ht";
          navNext = "<leader>hn";
          navPrev = "<leader>hp";
        };
      };

      nvim-colorizer = {
        enable = true;
      };

      todo-comments = {
        enable = true;
      };

      indent-blankline = {
        enable = true;
        whitespace = {
          highlight = [ "IndentBlanklineSpaceChar" "IndentBlanklineSpaceCharBlankline" ];
        };
        scope = {
          showStart = false;
          showEnd = false;
        };
        exclude = {
          filetypes = [
            "help"
            "terminal"
            "lazy"
            "lspinfo"
            "TelescopePrompt"
            "TelescopeResults"
            "Alpha"
            ""
          ];
        };
      };

      which-key = {
        enable = true;

        registrations = {
          "<leader>f" = "+file/find";
          "<leader>h" = "+harpoon";
          "<leader>s" = "+spectre";
          "<leader>r" = "+refactor";
        };
      };
    };

    extraPlugins = with pkgs; [
      vimPlugins.nvim-spectre
      vimPlugins.refactoring-nvim

      # for yanky
      vimPlugins.sqlite-lua
      vimExtraPlugins.yanky-nvim
    ];

    # TODO: look at combing refactor and code actions ? 
    extraConfigLua =
      ''
        require("spectre").setup()

        -- yanky
        require("telescope").load_extension("yank_history")
        require("yanky").setup({
        	highlight = { timer = 250 },
        	ring = { storage = jit.os:find("Windows") and "shada" or "sqlite" },
        })

        -- TODO: move to keymaps
        vim.keymap.set({"n","x"}, "p", "<Plug>(YankyPutAfter)")
        vim.keymap.set({"n","x"}, "P", "<Plug>(YankyPutBefore)")
        vim.keymap.set({"n","x"}, "gp", "<Plug>(YankyGPutAfter)")
        vim.keymap.set({"n","x"}, "gP", "<Plug>(YankyGPutBefore)")
        vim.keymap.set("n", "<c-n>", "<Plug>(YankyCycleForward)")
        vim.keymap.set("n", "<c-p>", "<Plug>(YankyCycleBackward)")

        -- refactoring
        require('refactoring').setup()
        vim.keymap.set("x", "<leader>re", ":Refactor extract ")
        vim.keymap.set("x", "<leader>rf", ":Refactor extract_to_file ")

        vim.keymap.set("x", "<leader>rv", ":Refactor extract_var ")

        vim.keymap.set({ "n", "x" }, "<leader>ri", ":Refactor inline_var")

        vim.keymap.set( "n", "<leader>rI", ":Refactor inline_func")

        vim.keymap.set("n", "<leader>rb", ":Refactor extract_block")
        vim.keymap.set("n", "<leader>rbf", ":Refactor extract_block_to_file")
      '';
  };
}
