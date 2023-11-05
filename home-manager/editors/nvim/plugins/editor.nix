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
      {
        action = "<cmd>Refactor extract<cr>";
        key = "<leader>re";
        options = {
          desc = "Refactor extract";
        };
        mode = [
          "x"
        ];
      }
      {
        action = "<cmd>Refactor extract_to_file<cr>";
        key = "<leader>rf";
        options = {
          desc = "Refactor extract to file";
        };
        mode = [
          "x"
        ];
      }
      {
        action = "<cmd>Refactor extract_var<cr>";
        key = "<leader>rv";
        options = {
          desc = "Refactor variable";
        };
        mode = [
          "x"
        ];
      }
      {
        action = "<cmd>Refactor inline_var<cr>";
        key = "<leader>ri";
        options = {
          desc = "Refactor inline variable";
        };
        mode = [
          "x"
          "n"
        ];
      }
      {
        action = "<cmd>Refactor inline_func<cr>";
        key = "<leader>rI";
        options = {
          desc = "Refactor inline function";
        };
        mode = [
          "n"
        ];
      }
      {
        action = "<cmd>Refactor extract_block<cr>";
        key = "<leader>rb";
        options = {
          desc = "Refactor extract block";
        };
        mode = [
          "n"
        ];
      }
      {
        action = "<cmd>Refactor extract_block_to_file<cr>";
        key = "<leader>rbf";
        options = {
          desc = "Refactor extract block to file";
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
        triggerEvents = [ "InsertLeave" ];
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

      refactoring = {
        enable = true;
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
      vimPlugins.tabout-nvim

      # for yanky
      vimPlugins.sqlite-lua
      vimExtraPlugins.yanky-nvim
    ];

    # TODO: look at combing refactor and code actions ? 
    extraConfigLua =
      ''
        				require("tabout").setup()

                require("spectre").setup()

                -- yanky
                require("telescope").load_extension("yank_history")
                require("yanky").setup({
                	highlight = { timer = 250 },
                	ring = { storage = "sqlite" },
                })

                -- TODO: move to keymaps
                vim.keymap.set({"n","x"}, "p", "<Plug>(YankyPutAfter)")
                vim.keymap.set({"n","x"}, "P", "<Plug>(YankyPutBefore)")
                vim.keymap.set({"n","x"}, "gp", "<Plug>(YankyGPutAfter)")
                vim.keymap.set({"n","x"}, "gP", "<Plug>(YankyGPutBefore)")
                vim.keymap.set("n", "<c-n>", "<Plug>(YankyCycleForward)")
                vim.keymap.set("n", "<c-p>", "<Plug>(YankyCycleBackward)")
      '';
  };
}
