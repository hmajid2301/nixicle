{
  programs.nixvim = {
    extraConfigLua =
      # lua
      ''
        local dap, dapui = require("dap"),require("dapui")
        dap.listeners.after.event_initialized["dapui_config"]=function()
        	dapui.open()
        end
        dap.listeners.before.event_terminated["dapui_config"]=function()
        	dapui.close()
        end
        dap.listeners.before.event_exited["dapui_config"] = function()
        	dapui.close()
        end
      '';

    plugins.which-key.registrations = {
      "<leader>d" = "+debug";
    };

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
        dap-ui = {
          enable = true;
          layouts = [
            {
              elements = [
                {
                  id = "scopes";
                  size = 0.25;
                }
                {
                  id = "breakpoints";
                  size = 0.25;
                }
                {
                  id = "stacks";
                  size = 0.25;
                }
                {
                  id = "watches";
                  size = 0.25;
                }
              ];
              position = "left";
              size = 40;
            }
            {
              elements = [
                {
                  id = "repl";
                  size = 0.5;
                }
                {
                  id = "console";
                  size = 0;
                }
              ];
              position = "bottom";
              size = 10;
            }
          ];
        };
        dap-virtual-text.enable = true;
      };
    };

    keymaps = [
      {
        action =
          # lua
          ''
            function()
              require('dap').continue()
            end
          '';
        key = "<leader>dc";
        lua = true;
        options = {
          desc = "Continue";
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
              require('dap').step_over()
            end
          '';
        key = "<leader>dO";
        lua = true;
        options = {
          desc = "Step over";
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
              require('dap').step_into()
            end
          '';
        key = "<leader>di";
        lua = true;
        options = {
          desc = "Step Into";
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
              require('dap').step_out()
            end
          '';
        key = "<leader>do";
        lua = true;
        options = {
          desc = "Step Out";
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
              require('dap').pause()
            end
          '';
        key = "<leader>dp";
        lua = true;
        options = {
          desc = "Pause";
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
              require('dap').toggle_breakpoint()
            end
          '';
        key = "<leader>db";
        lua = true;
        options = {
          desc = "Toggle Breakpoint";
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
            	require('dap').set_breakpoint(vim.fn.input('Breakpoint condition: '))
            end
          '';
        key = "<leader>dB";
        lua = true;
        options = {
          desc = "Breakpoint (conditional)";
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
              require('dap').repl.toggle()
            end
          '';
        key = "<leader>dR";
        lua = true;
        options = {
          desc = "Toggle REPL";
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
            	local dap = require('dap')
            	dap.disconnect()
            	dap.close()
            	dap.run_last()
            end
          '';
        key = "<leader>dr";
        lua = true;
        options = {
          desc = "Restart Debugger";
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
              require('dap').run_last()
            end
          '';
        key = "<leader>dr";
        lua = true;
        options = {
          desc = "Run Last";
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
              require('dap').session()
            end
          '';
        key = "<leader>ds";
        lua = true;
        options = {
          desc = "Session";
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
              require('dap').terminate()
            end
          '';
        key = "<leader>dt";
        lua = true;
        options = {
          desc = "Terminate";
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
              require('dap.ui.widgets').hover()
            end
          '';
        key = "<leader>dw";
        lua = true;
        options = {
          desc = "Hover Widget";
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
              require('dapui').toggle()
            end
          '';
        key = "<leader>du";
        lua = true;
        options = {
          desc = "Toggle UI";
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
              require('dapui').eval()
            end
          '';
        key = "<leader>de";
        lua = true;
        options = {
          desc = "Eval";
        };
        mode = [
          "n"
        ];
      }
    ];
  };
}
