{
  programs.nixvim = {
    keymaps = [
      {
        action = "<C-d>zz";
        key = "<C-d>";
        options = {
          desc = "Keep cursor in middle when jumping";
        };
        mode = [
          "n"
        ];
      }
      {
        action = "<C-u>zz";
        key = "<C-u>";
        options = {
          desc = "Keep cursor in middle when jumping";
        };
        mode = [
          "n"
        ];
      }
      {
        action = ":m ->+1<CR>gv=gv";
        key = "J";
        options = {
          desc = "Move selected lines up";
        };
        mode = [
          "v"
        ];
      }
      {
        action = ":m <-2<CR>gv=gv";
        key = "K";
        options = {
          desc = "Move selected lines up";
        };
        mode = [
          "v"
        ];
      }
      {
        action = "mzJ`z";
        key = "bJL";
        options = {
          desc = "Combine line into one";
        };
        mode = [
          "n"
        ];
      }
      {
        action = "nzzzv";
        key = "n";
        options = {
          desc = "Keep cursor in middle when searching";
        };
        mode = [
          "n"
        ];
      }
      {
        action = "Nzzzv";
        key = "N";
        options = {
          desc = "Keep cursor in middle when searching";
        };
        mode = [
          "n"
        ];
      }
      {
        action = "v:count == 0 ? 'gj' : 'j'";
        key = "j";
        options = {
          silent = true;
          expr = true;
        };
        mode = [
          "n"
        ];
      }
      {
        action = "v:count == 0 ? 'gk' : 'k'";
        key = "k";
        options = {
          silent = true;
          expr = true;
        };
        mode = [
          "n"
        ];
      }
      {
        action = "<C-w>v";
        key = "<leader>|";
        options = {
          desc = "Split window right";
        };
        mode = [
          "n"
        ];
      }
      {
        action = "<C-w>s";
        key = "<leader>-";
        options = {
          desc = "Split window below";
        };
        mode = [
          "n"
        ];
      }
      {
        action = "<cmd>w<cr><esc>";
        key = "<C-s>";
        options = {
          desc = "Save file";
        };
        mode = [
          "n"
          "v"
          "x"
        ];
      }
      {
        action = "'_dP";
        key = "<leader>p";
        options = {
          desc = "Paste without updating buffer";
        };
        mode = [
          "v"
        ];
      }
      {
        action = ">gv";
        key = ">";
        options = {
          desc = "Stay in visual mode during outdent";
        };
        mode = [
          "v"
          "x"
        ];
      }
      {
        action = "<gv";
        key = "<";
        options = {
          desc = "Stay in visual mode during indent";
        };
        mode = [
          "v"
          "x"
        ];
      }
    ];
  };
}
