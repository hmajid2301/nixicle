{
  programs.nixvim = {
    plugins.dap = {
      enable = true;
      signs = {
        dapBreakpoint = {
          text = " ";
          texthl = "DiagnosticInfo";
        };
        dapBreakpointCondition = {
          text = " ";
          texthl = "DiagnosticInfo";
        };
        dapBreakpointRejected = {
          text = " ";
          texthl = "DiagnosticError";
        };
        dapLogPoint = {
          text = " ";
          texthl = "DiagnosticInfo";
        };
        dapStopped = {
          text = "󰁕 ";
          texthl = "DiagnosticWarn";
          linehl = "DapStoppedLine";
          numhl = "DapStoppedLine";
        };
      };

      extensions = {
        dap-ui.enable = true;
        dap-virtual-text.enable = true;
      };
    };

    maps = {
      normal = {
        "<leader>dc" = {
          action =
            # lua
            ''
              function()
                require('dap').continue()
              end
            '';
          desc = "Continue";
          lua = true;
        };
        "<leader>dO" = {
          action =
            # lua
            ''
              function()
                require('dap').step_over()
              end
            '';
          desc = "Step Over";
          lua = true;
        };
        "<leader>di" = {
          action =
            # lua
            ''
              function()
                require('dap').step_into()
              end
            '';
          desc = "Step Into";
          lua = true;
        };
        "<leader>do" = {
          action =
            # lua
            ''
              function()
                require('dap').step_out()
              end
            '';
          desc = "Step Out";
          lua = true;
        };
        "<leader>dp" = {
          action =
            # lua
            ''
              function()
                require('dap').pause()
              end
            '';
          desc = "Pause";
          lua = true;
        };
        "<leader>db" = {
          action =
            # lua
            ''
              function()
                require('dap').toggle_breakpoint()
              end
            '';
          desc = "Toggle Breakpoint";
          lua = true;
        };
        "<leader>dB" = {
          action =
            # lua
            ''
              function()
                require('dap').set_breakpoint(vim.fn.input('Breakpoint condition: '))
              end
            '';
          desc = "Breakpoint Condition";
          lua = true;
        };
        "<leader>dr" = {
          action =
            # lua
            ''
              function()
                require('dap').repl.toggle()
              end
            '';
          desc = "Toggle REPL";
          lua = true;
        };
        "<leader>dl" = {
          action =
            # lua
            ''
              function()
                require('dap').run_last()
              end
            '';
          desc = "Run Last";
          lua = true;
        };
        "<leader>ds" = {
          action =
            # lua
            ''
              function()
                require('dap').session()
              end
            '';
          desc = "Session";
          lua = true;
        };
        "<leader>dt" = {
          action =
            # lua
            ''
              function()
                require('dap').terminate()
              end
            '';
          desc = "Terminate";
          lua = true;
        };
        "<leader>dw" = {
          action =
            # lua
            ''
              function()
                require('dap.ui.widgets').hover()
              end
            '';
          desc = "Hover Widget";
          lua = true;
        };
        "<leader>du" = {
          action =
            # lua
            ''
              function()
                require('dapui').toggle()
              end
            '';
          desc = "Debug UI";
          lua = true;
        };
        "<leader>de" = {
          action =
            # lua
            ''
              function()
                require('dapui').eval()
              end
            '';
          desc = "Eval";
          lua = true;
        };
      };
    };

    extraConfigLua =
      # lua
      ''
        require("which-key").register({
          ["<leader>d"] = { name = "+debug" },
        })
      '';
  };
}
