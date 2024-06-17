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
        action = "<cmd>ToggleTermToggleAll<cr>";
        key = "<leader>gg";
        mode = ["n"];
      }
      {
        action = "<cmd>lua require('smart-splits').resize_left()<cr>";
        key = "<A-h>";
        mode = ["n"];
      }
      {
        action = "<cmd>lua require('smart-splits').resize_down()<cr>";
        key = "<A-j>";
        mode = ["n"];
      }
      {
        action = "<cmd>lua require('smart-splits').resize_up()<cr>";
        key = "<A-k>";
        mode = ["n"];
      }
      {
        action = "<cmd>lua require('smart-splits').resize_right()<cr>";
        key = "<A-l>";
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
    ];

    plugins = {
      arrow = {
        enable = true;
        settings = {
          leader_key = "<Space>h";
        };
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

      spectre = {
        enable = true;
      };

      smart-splits = {
        enable = true;
      };

      undotree = {
        enable = true;
      };

      which-key = {
        enable = true;

        registrations = {
          "<leader>f" = "file/find";
          "<leader>s" = "spectre";
        };
      };

      toggleterm = {
        enable = true;
        settings = {
          shell = "fish";
          direction = "float";
        };
      };
    };

    extraPlugins = with pkgs.vimPlugins; [
      aerial-nvim
      outline-nvim
      gx-nvim
      tmux-nvim
    ];

    extraConfigLua =
      # lua
      ''
        require("outline").setup()
        require("aerial").setup()
        require("gx").setup()
        -- TODO: check if smart-splits yanks from tmux
        -- require("tmux").setup()

        -- function _G.set_terminal_keymaps()
        --   local opts = {buffer = 0}
        --   vim.keymap.set('t', '<esc>', [[<C-\><C-n>]], opts)
        --   vim.keymap.set('t', 'jk', [[<C-\><C-n>]], opts)
        --   vim.keymap.set('t', '<C-h>', [[<Cmd>wincmd h<CR>]], opts)
        --   vim.keymap.set('t', '<C-j>', [[<Cmd>wincmd j<CR>]], opts)
        --   vim.keymap.set('t', '<C-k>', [[<Cmd>wincmd k<CR>]], opts)
        --   vim.keymap.set('t', '<C-l>', [[<Cmd>wincmd l<CR>]], opts)
        --   vim.keymap.set('t', '<C-w>', [[<C-\><C-n><C-w>]], opts)
        -- end

        -- if you only want these mappings for toggle term use term://*toggleterm#* instead
        vim.cmd('autocmd! TermOpen term://* lua set_terminal_keymaps()')
      '';
  };
}
