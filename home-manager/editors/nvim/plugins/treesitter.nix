{ config
, pkgs
, ...
}: {
  programs.nixvim = {
    plugins = {
      treesitter = {
        enable = true;
        nixvimInjections = true;
        indent = false;

        incrementalSelection = {
          enable = true;
          keymaps = {
            initSelection = "<C-space>";
            nodeIncremental = "<C-space>";
            nodeDecremental = "<bs>";
          };
        };

        grammarPackages = with config.programs.nixvim.plugins.treesitter.package.builtGrammars; [
          c
          css
          bash
          fish

          vim
          vimdoc

          json
          toml
        ];
      };
    };

    extraPlugins = with pkgs.vimPlugins; [
      nvim-treesitter-textobjects
    ];

    extraConfigLua = ''
      require'nvim-treesitter.configs'.setup {
      	textobjects = {
      		select = {
      			enable = true,
      			keymaps = {
      				["aa"] = "@parameter.outer",
      				["ia"] = "@parameter.inner",
      				["af"] = "@function.outer",
      				["if"] = "@function.inner",
      				["ac"] = "@class.outer",
      				["ic"] = "@class.inner",
      				["ai"] = "@conditional.outer",
      				["ii"] = "@conditional.inner",
      				["al"] = "@loop.outer",
      				["il"] = "@loop.inner",
      			},
      		},

      		move = {
      			enable = true,
      			set_jumps = true,
      			goto_next_start = {
      				["]m"] = "@function.outer",
      				["]]"] = "@class.outer",
      			},
      			goto_next_end = {
      				["]M"] = "@function.outer",
      				["]["] = "@class.outer",
      			},
      			goto_previous_start = {
      				["[m"] = "@function.outer",
      				["[["] = "@class.outer",
      			},
      			goto_previous_end = {
      				["[M"] = "@function.outer",
      				["[]"] = "@class.outer",
      			},
      		},

      		swap = {
      			enable = true,
      			swap_next = {
      				[')a'] = '@parameter.inner',
      			},
      			swap_previous = {
      				[')A'] = '@parameter.inner',
      			},
      		},
      	},
      }

      local ts_repeat_move = require("nvim-treesitter.textobjects.repeatable_move")

      -- vim way: ; goes to the direction you were moving.
      vim.keymap.set({ "n", "x", "o" }, ";", ts_repeat_move.repeat_last_move)
      vim.keymap.set({ "n", "x", "o" }, ",", ts_repeat_move.repeat_last_move_opposite)

      -- Optionally, make builtin f, F, t, T also repeatable with ; and ,
      vim.keymap.set({ "n", "x", "o" }, "f", ts_repeat_move.builtin_f)
      vim.keymap.set({ "n", "x", "o" }, "F", ts_repeat_move.builtin_F)
      vim.keymap.set({ "n", "x", "o" }, "t", ts_repeat_move.builtin_t)
      vim.keymap.set({ "n", "x", "o" }, "T", ts_repeat_move.builtin_T)
    '';
  };
}
