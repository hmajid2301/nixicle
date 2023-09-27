{ config
, pkgs
, ...
}: {
  home.packages = with pkgs; [
    tree-sitter
  ];

  programs.nixvim = {
    plugins = {
      treesitter = {
        enable = true;
        nixvimInjections = true;
        indent = false;

        incrementalSelection = {
          enable = true;
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

      # treesitter-rainbow.enable = true;
      # treesitter-refactor = {
      #   enable = true;
      #   highlightDefinitions.enable = true;
      # };
      #
      # treesitter-context = {
      #   enable = true;
      # };
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
                    -- You can use the capture groups defined in textobjects.scm
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
                  set_jumps = true, -- whether to set jumps in the jumplist
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
      							['<leader>a'] = '@parameter.inner',
      						},
      						swap_previous = {
      							['<leader>A'] = '@parameter.inner',
      						},
      					},
              },
            }
    '';
  };
}
