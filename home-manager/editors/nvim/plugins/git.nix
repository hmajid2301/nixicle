{pkgs, ...}: {
  programs.nixvim = {
    maps = {
      normal = {
        "<leader>gg" = {
          action = "<cmd> TermExec cmd='lazygit'<cr>";
          desc = "Open lazygit";
        };
      };
    };
    plugins = {
      gitsigns = {
        enable = true;
        currentLineBlame = true;
        signs = {
          add = {text = "│";};
          change = {text = "│";};
          delete = {text = "󰍵";};
          topdelete = {text = "‾";};
          changedelete = {text = "~";};
          untracked = {text = "│";};
        };

        onAttach.function =
          # lua
          ''
            function(buffer)
              local gs = package.loaded.gitsigns

              local function map(mode, l, r, desc)
                vim.keymap.set(mode, l, r, { buffer = buffer, desc = desc })
              end

              local Terminal  = require('toggleterm.terminal').Terminal
              local lazygit = Terminal:new({ cmd = "lazygit", hidden = true })

              function _lazygit_toggle()
                lazygit:toggle()
              end

              map("n", "<leader>gg", "<cmd>lua _lazygit_toggle()<CR>")
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
