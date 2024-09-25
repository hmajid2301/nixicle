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
        action = ":m .+1<CR>==";
        key = "<leader>mj";
        options = {
          desc = "Move selected lines down";
        };
        mode = [
          "n"
        ];
      }
      {
        action = ":m .-2<CR>==";
        key = "<leader>mk";
        options = {
          desc = "Move selected lines up";
        };
        mode = [
          "n"
        ];
      }
      {
        action = ":m ->+1<CR>gv=gv";
        key = "<leader>mj";
        options = {
          desc = "Move selected lines down in visual mode";
        };
        mode = [
          "v"
        ];
      }
      {
        action = ":m <-2<CR>gv=gv";
        key = "<leader>mk";
        options = {
          desc = "Move selected lines up in visual mode";
        };
        mode = [
          "v"
        ];
      }
      {
        action = "mzJ`z";
        key = "J";
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
      {
        action = "<cmd>cnext<CR>zz";
        key = "<C-n>";
        options = {
          desc = "Go to next item in quickfix list and center cursor";
        };
        mode = [
          "n"
        ];
      }
      {
        action = "<cmd>cprev<CR>zz";
        key = "<C-p>";
        options = {
          desc = "Go to previous item in quickfix list and center cursor";
        };
        mode = [
          "n"
        ];
      }
      {
        action = "<cmd>lnext<CR>zz";
        key = "<leader>k";
        options = {
          desc = "Go to next item in location list and center cursor";
        };
        mode = [
          "n"
        ];
      }
      {
        action = "<cmd>lprev<CR>zz";
        key = "<leader>j";
        options = {
          desc = "Go to previous item in location list and center cursor";
        };
        mode = [
          "n"
        ];
      }
      {
        action = "<cmd>cmp.mapping.scroll_docs(-4)<CR>";
        key = "<C-b>";
        options = {
          desc = "Scroll docs down";
        };
        mode = [
          "n"
        ];
      }
      {
        action = "<cmd>cmp.mapping.scroll_docs(4)<CR>";
        key = "<C-f>";
        options = {
          desc = "Scroll docs up";
        };
        mode = [
          "n"
        ];
      }
    ];
  };
}
