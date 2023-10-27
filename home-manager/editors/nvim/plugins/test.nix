{ pkgs, ... }: {
  programs.nixvim = {
    plugins.which-key.registrations = {
      "<leader>t" = "+test";
    };



    keymaps = [
      {
        action =
          # lua
          ''
            function()
              require("neotest").run.run(vim.fn.expand("%"))
            end
          '';
        key = "<leader>tt";
        lua = true;
        options = {
          desc = "Run file";
        };
        mode = [
          "n"
        ];
      }
      {
        action =
          # lua
          ''
            function()
              require("neotest").run.run(vim.loop.cwd())
            end
          '';
        key = "<leader>tT";
        lua = true;
        options = {
          desc = "Run all test file(s)";
        };
        mode = [
          "n"
        ];
      }
      {
        action =
          # lua
          ''
            function()
              require("neotest").stop()
            end
          '';
        key = "<leader>tS";
        lua = true;
        options = {
          desc = "Stop Tests";
        };
        mode = [
          "n"
        ];
      }
      {
        action =
          # lua
          ''
            function()
              require("neotest").run().run()
            end
          '';
        key = "<leader>tr";
        lua = true;
        options = {
          desc = "Run Nearest";
        };
        mode = [
          "n"
        ];
      }
      {
        action =
          # lua
          ''
            function()
              require("neotest").summary().toggle()
            end
          '';
        key = "<leader>ts";
        lua = true;
        options = {
          desc = "Toggle Summary";
        };
        mode = [
          "n"
        ];
      }
      {
        action =
          # lua
          ''
            function()
            	require("neotest").output.open({ enter = true, auto_close = true })
            end
          '';
        key = "<leader>to";
        lua = true;
        options = {
          desc = "Show Output";
        };
        mode = [
          "n"
        ];
      }
      {
        action =
          # lua
          ''
            function()
              require("neotest").output_panel.toggle()
            end
          '';
        key = "<leader>tO";
        lua = true;
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
    extraConfigLua =
      ''
        require("which-key").register({
        	["<leader>t"] = { name = "+test" },
        })

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
        			args = { "-tags=integration" }
        		},
        	},
        })
      '';
  };
}
