{
  pkgs,
  inputs,
  ...
}: let
  advanced-git-search-nvim = pkgs.vimUtils.buildVimPlugin {
    version = "latest";
    pname = "advanced-git-search.nvim";
    src = inputs.advanced-git-search-nvim;
  };
in {
  programs.nixvim = {
    extraPlugins = with pkgs.vimPlugins; [
      advanced-git-search-nvim
      lazygit-nvim
    ];

    extraConfigLua = ''
      require("advanced_git_search.fzf").setup{}
      require("telescope").load_extension("advanced_git_search")

      local set = vim.opt -- set options
      set.fillchars = set.fillchars + 'diff:╱'
    '';

    keymaps = [
      {
        action = "<cmd>LazyGit<cr>";
        key = "<leader>gg";
        options = {
          desc = "Open LazyGit";
        };
        mode = [
          "n"
        ];
      }
      {
        action = ''<cmd>lua function() require("telescope").extensions.git_worktree.git_worktrees() end<cr>'';
        key = "<leader>gt";
        options = {
          desc = "Git Worktree Switch";
        };
        mode = [
          "n"
        ];
      }
      {
        action = ''<cmd>lua function() require("telescope").extensions.git_worktree.create_git_worktree() end<cr>'';
        key = "<leader>gc";
        options = {
          desc = "Git Worktree Create";
        };
        mode = [
          "n"
        ];
      }
    ];

    plugins = {
      which-key.registrations = {
        "<leader>g" = "git";
      };

      git-worktree = {
        enable = true;
        enableTelescope = true;
      };

      diffview = {
        enable = true;
      };

      fzf-lua = {
        enable = true;
      };

      fugitive = {
        enable = true;
      };

      gitsigns = {
        enable = true;
        settings = {
          current_line_blame = false;
          signs = {
            add = {text = "│";};
            change = {text = "│";};
            delete = {text = "󰍵";};
            topdelete = {text = "‾";};
            changedelete = {text = "~";};
            untracked = {text = "│";};
          };
        };
      };
    };
  };
}
