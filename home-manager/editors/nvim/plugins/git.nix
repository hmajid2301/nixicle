{ pkgs, ... }: {
  programs.nixvim = {
    extraPlugins = with pkgs.vimPlugins; [
      git-worktree-nvim
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
    ];

    extraConfigLua =
      ''
        require("git-worktree").setup()
        require("telescope").load_extension("git_worktree")
      '';

    plugins = {
      which-key.registrations = {
        "<leader>g" = "+git";
        "<leader>gh" = "+hunks";
      };
      neogit = {
        enable = true;
      };

      gitsigns = {
        enable = true;
        currentLineBlame = false;
        signs = {
          add = { text = "│"; };
          change = { text = "│"; };
          delete = { text = "󰍵"; };
          topdelete = { text = "‾"; };
          changedelete = { text = "~"; };
          untracked = { text = "│"; };
        };

        onAttach.function =
          # lua
          ''
            function(buffer)
            	local gs = package.loaded.gitsigns

            	local function map(mode, l, r, desc)
            		vim.keymap.set(mode, l, r, { buffer = buffer, desc = desc })
            	end

            	map("n", "<leader>gt", function() require("telescope").extensions.git_worktree.git_worktrees() end, "Git worktree switch")
            	map("n", "<leader>gc", function() require("telescope").extensions.git_worktree.create_git_worktree() end, "New Git worktree")
            	map("n", "]h", gs.next_hunk, "Next Hunk")
            	map("n", "[h", gs.prev_hunk, "Prev Hunk")
            	map({ "n", "v" }, "<leader>ghs", ":Gitsigns stage_hunk<CR>", "Stage Hunk")
            	map({ "n", "v" }, "<leader>ghr", ":Gitsigns reset_hunk<CR>", "Reset Hunk")
            	map("n", "<leader>ghS", gs.stage_buffer, "Stage Buffer")
            	map("n", "<leader>ghu", gs.undo_stage_hunk, "Undo Stage Hunk")
            	map("n", "<leader>ghR", gs.reset_buffer, "Reset Buffer")
            	map("n", "<leader>ghp", gs.preview_hunk, "Preview Hunk")
            	map("n", "<leader>ghb", function() gs.blame_line({ full = true }) end, "Blame Line")
            	map("n", "<leader>ghd", gs.diffthis, "Diff This")
            	map("n", "<leader>ghD", function() gs.diffthis("~") end, "Diff This ~")
            	map({ "o", "x" }, "gh", ":<C-U>Gitsigns select_hunk<CR>", "GitSigns Select Hunk")
            end
          '';
      };
    };
  };
}
