{
  programs.nixvim = {
    maps = {
      normalVisualOp = {
        "<C-s>" = {
          action = "<cmd>w<cr><esc>";
          desc = "Save File";
        };
      };
      normal = {
        "<C-d>" = {
          action = "<C-d>zz";
          desc = "Keep cursor in middle when jumping";
        };
        "<C-u>" = {
          action = "<C-u>zz";
          desc = "Keep cursor in middle when jumping";
        };
        "J" = {
          action = "mzJ`z";
          desc = "Keep cursor in middle when jumping";
        };
        "n" = {
          action = "nzzzv";
          desc = "Keep cursor in middle when searching";
        };
        "N" = {
          action = "Nzzzv";
          desc = "Keep cursor in middle when searching";
        };
        "j" = {
          action = "v:count == 0 ? 'gj' : 'j'";
          silent = true;
          expr = true;
        };
        "k" = {
          action = "v:count == 0 ? 'gk' : 'k'";
          silent = true;
          expr = true;
        };
        "<leader>|" = {
          action = "<C-W>v";
          desc = "Split window right";
        };
        "<leader>-" = {
          action = "<C-W>s";
          desc = "Split window below";
        };
        "<S-H>" = {
          desc = "Go to previous buffer";
          action = "<CMD>BufferLineCyclePrev<CR>";
        };
        "<S-L>" = {
          desc = "Go to next buffer";
          action = "<CMD>BufferLineCycleNext<CR>";
        };
        "[b" = {
          desc = "Go to previous buffer";
          action = "<CMD>BufferLineCyclePrev<CR>";
        };
        "]b>" = {
          desc = "Go to next buffer";
          action = "<CMD>BufferLineCycleNext<CR>";
        };
      };

      visualOnly = {
        "<leader>p" = {
          action = "'_dP";
          desc = "Paste with out updating buffer";
        };
      };

      visual = {
        ">" = {
          action = ">gv";
          desc = "Stay in visual mode during indent";
        };
        "<" = {
          action = "<gv";
          desc = "Stay in visual mode during outdent";
        };
      };
    };
  };
}
