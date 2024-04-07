{
  inputs,
  pkgs,
  lib,
  ...
}: let
  arrow-nvim = pkgs.vimUtils.buildVimPlugin {
    version = "latest";
    pname = "arrow.nvim";
    src = inputs.arrow-nvim;
  };
in {
  imports = lib.snowfall.fs.get-non-default-nix-files ./.;

  programs.nixvim = {
    clipboard = {
      providers.wl-copy.enable = true;
      register = "unnamedplus";
    };

    keymaps = [
      {
        action = "<cmd>lua require('flash').jump()<cr>";
        key = "<leader>ls";
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
        key = "<leader>lt";
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
          desc = "Show undo telescope";
        };
        mode = [
          "n"
        ];
      }
      {
        action = "<cmd>UndotreeToggle<cr>";
        key = "<leader>ut";
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
        action = "<cmd>lua require('spectre').open_visual({select_word=true})<cr>";
        key = "<leader>sw";
        options = {
          desc = "Replace current word";
        };
        mode = [
          "n"
        ];
      }
      {
        action = "<cmd>lua require('spectre').open_visual()<cr>";
        key = "<leader>sw";
        options = {
          desc = "Replace current word";
        };
        mode = [
          "v"
        ];
      }
      {
        action = "<cmd>lua require('spectre').open_file_search({select_word=true})<cr>";
        key = "<leader>sp";
        options = {
          desc = "Replace in current buffer";
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

      flash = {
        enable = true;
        modes = {
          char = {
            jumpLabels = true;
          };
        };
      };

      navbuddy = {
        enable = true;
        lsp.autoAttach = true;
      };

      nvim-lightbulb = {
        enable = true;
      };

      nvim-colorizer = {
        enable = true;
      };

      todo-comments = {
        enable = true;
      };

      indent-blankline = {
        enable = true;
        settings = {
          whitespace = {
            highlight = ["IndentBlanklineSpaceChar" "IndentBlanklineSpaceCharBlankline"];
          };
          scope = {
            show_start = false;
            show_end = false;
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
      };

      undotree = {
        enable = true;
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
      zellij = {
        enable = true;
        settings = {
          vimTmuxNavigatorKeybinds = true;
        };
      };
    };

    extraPlugins = [
      pkgs.vimPlugins.nvim-spectre
      arrow-nvim
    ];

    extraConfigLua = ''
      require("spectre").setup()
      require("arrow").setup({
        show_icons = true,
        leader_key = "<leader>h",
      })
    '';
  };
}
