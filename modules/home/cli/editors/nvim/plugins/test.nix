{pkgs, ...}: {
  programs.nixvim = {
    keymaps = [
      {
        action = "<cmd>lua require('neotest').run.run(vim.fn.expand('%'))<cr>";
        key = "<leader>tt";
        options = {
          desc = "Run file";
        };
        mode = [
          "n"
        ];
      }
      {
        action = ''<cmd>lua require("neotest").run.run(vim.loop.cwd())<cr>'';
        key = "<leader>tT";
        options = {
          desc = "Run all test file(s)";
        };
        mode = [
          "n"
        ];
      }
      {
        action = ''<cmd>lua require("neotest").stop()<cr>'';
        key = "<leader>tS";
        options = {
          desc = "Stop Tests";
        };
        mode = [
          "n"
        ];
      }
      {
        action = ''<cmd>lua require("neotest").run.run()<cr>'';
        key = "<leader>tr";
        options = {
          desc = "Run Nearest";
        };
        mode = [
          "n"
        ];
      }
      {
        action = ''<cmd>lua require("neotest").summary.toggle()<cr>'';
        key = "<leader>ts";
        options = {
          desc = "Toggle Summary";
        };
        mode = [
          "n"
        ];
      }
      {
        action = ''<cmd>lua require("neotest").output.open({ enter = true, auto_close = true })<cr>'';
        key = "<leader>to";
        options = {
          desc = "Show Output";
        };
        mode = [
          "n"
        ];
      }
      {
        action = ''<cmd>lua require("neotest").run.run({ suite = false, strategy = "dap" })<cr>'';
        key = "<leader>td";
        options = {
          desc = "Debug nearest test";
        };
        mode = [
          "n"
        ];
      }
      {
        action = ''<cmd>lua require("neotest").output_panel.toggle()<cr>'';
        key = "<leader>tO";
        options = {
          desc = "Toggle Output";
        };
        mode = [
          "n"
        ];
      }
    ];

    plugins = {
      coverage.enable = true;
      neotest = {
        enable = true;
        settings = {
          output.open_on_run = true;
          status.virtual_text = true;
        };
      };
    };
  };
}
