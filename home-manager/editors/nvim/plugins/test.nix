{pkgs, ...}: {
  programs.nixvim = {
    plugins.which-key.registrations = {
      "<leader>t" = "+test";
    };

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

    extraPlugins = with pkgs.vimPlugins; [
      neotest
      neotest-python
      neotest-go
    ];

    # TODO: workout how to move neotest to specific language files
    extraConfigLua = ''
      local neotest = require('neotest')
      neotest.setup({
      	status = { virtual_text = true },
      	output = { open_on_run = true },
      	adapters = {
      		require('neotest-python') {},
      		require('neotest-go') {
      			experimental = {
      				test_table = true,
      			},
      			args = { "-tags=unit,integration,e2e,bdd" }
      		},
      	},
      })
    '';
  };
}
