{pkgs, ...}: {
  programs.nixvim = {
    extraPlugins = with pkgs.vimPlugins; [
      advanced-git-search-nvim
    ];

    extraConfigLua = ''
      require("advanced_git_search.fzf").setup{}
      require("telescope").load_extension("advanced_git_search")

      local set = vim.opt -- set options
      set.fillchars = set.fillchars + 'diff:╱'
    '';

    keymaps = [
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

      neogit = {
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
