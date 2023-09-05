{ pkgs, ... }: {
  programs.nixvim = {
    maps = {
      normal = {
        "<leader>tt" = {
          action =
            # lua
            ''
              function()
                require("neotest").run.run(vim.fn.expand("%"))
              end
            '';
          desc = "Run File";
          lua = true;
        };
        "<leader>tT" = {
          action =
            # lua
            ''
              function()
                require("neotest").run.run(vim.loop.cwd())
              end
            '';
          desc = "Run All Test Files";
          lua = true;
        };
        "<leader>tS" = {
          action =
            # lua
            ''
              function()
                require("neotest").stop()
              end
            '';
          desc = "Stop Tests";
          lua = true;
        };
        "<leader>tr" = {
          action =
            # lua
            ''
              function()
                require("neotest").run.run()
              end
            '';
          desc = "Run Nearest";
          lua = true;
        };
        # TODO: how to do language specific binding i.e. golang
        # "<leader>td" = {
        #   action =
        #     # lua
        #     ''
        #       function()
        #         require("neotest").run.run({strategy = "dap"})
        #       end
        #     '';
        #   desc = "Debug Test (Nearest)";
        #   lua = true;
        # };
        "<leader>ts" = {
          action =
            # lua
            ''
              function()
                require("neotest").summary.toggle()
              end
            '';
          desc = "Toggle Summary";
          lua = true;
        };
        "<leader>to" = {
          action =
            # lua
            ''
              function()
                require("neotest").output.open({ enter = true, auto_close = true })
              end
            '';
          desc = "Show Output";
          lua = true;
        };
        "<leader>tO" = {
          action =
            # lua
            ''
              function()
                require("neotest").output_panel.toggle()
              end
            '';
          desc = "Toggle Output Panel";
          lua = true;
        };
      };
    };

    extraPlugins = with pkgs.vimPlugins; [ neotest ];
    extraConfigLua =
      # lua
      ''
        require("which-key").register({
          ["<leader>t"] = { name = "+test" },
        })

        local neotest = require('neotest')
        neotest.setup({
          status = { virtual_text = true },
          output = { open_on_run = true },
        })
      '';
  };
}
