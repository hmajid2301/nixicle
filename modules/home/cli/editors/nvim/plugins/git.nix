{pkgs, ...}: {
  programs.nixvim = {
    extraPlugins = with pkgs.vimPlugins; [
      lazygit-nvim
    ];

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

      fugitive = {
        enable = true;
      };

      gitsigns = {
        enable = true;
        currentLineBlame = false;
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
}
