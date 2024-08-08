{
  inputs,
  pkgs,
  lib,
  ...
}: let
  gx-nvim = pkgs.vimUtils.buildVimPlugin {
    version = "latest";
    pname = "gx.nvim";
    src = inputs.gx-nvim;
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
        action = "<cmd>lua require('smart-splits').start_resize_mode()<cr>";
        key = "<leader>mr";
        mode = ["n"];
      }
      {
        action = "<cmd>lua require('smart-splits').move_cursor_left()<cr>";
        key = "<C-h>";
        mode = ["n"];
      }
      {
        action = "<cmd>lua require('smart-splits').move_cursor_down()<cr>";
        key = "<C-j>";
        mode = ["n"];
      }
      {
        action = "<cmd>lua require('smart-splits').move_cursor_up()<cr>";
        key = "<C-k>";
        mode = ["n"];
      }
      {
        action = "<cmd>lua require('smart-splits').move_cursor_right()<cr>";
        key = "<C-l>";
        mode = ["n"];
      }
      {
        action = "<cmd>lua require('smart-splits').move_cursor_previous()<cr>";
        key = "<C-\\>";
        mode = ["n"];
      }
      {
        action = "<cmd>lua require('smart-splits').swap_buf_left()<cr>";
        key = "<leader><leader>h";
        mode = ["n"];
      }
      {
        action = "<cmd>lua require('smart-splits').swap_buf_down()<cr>";
        key = "<leader><leader>j";
        mode = ["n"];
      }
      {
        action = "<cmd>lua require('smart-splits').swap_buf_up()<cr>";
        key = "<leader><leader>k";
        mode = ["n"];
      }
      {
        action = "<cmd>lua require('smart-splits').swap_buf_right()<cr>";
        key = "<leader><leader>l";
        mode = ["n"];
      }
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
        action = "<cmd>Browse<cr>";
        key = "gx";
        options = {
          desc = "Open link in Browser";
        };
        mode = [
          "n"
          "x"
        ];
      }
      {
        action = "<cmd>cclose<cr>";
        key = "xq";
        options = {
          desc = "Close quicklist/loclist";
        };
        mode = [
          "n"
          "x"
        ];
      }
    ];

    plugins = {
      arrow = {
        enable = true;
        settings = {
          leader_key = "<Space>h";
        };
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
        userDefaultOptions.tailwind = true;
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

      spectre = {
        enable = true;
      };

      smart-splits = {
        enable = true;
      };

      undotree = {
        enable = true;
      };
    };

    extraPlugins = [
      gx-nvim
    ];

    extraConfigLua =
      # lua
      ''
        require("gx").setup()
      '';
  };
}
