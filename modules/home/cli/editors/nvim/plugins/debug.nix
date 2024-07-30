{
  programs.nixvim = {
    extraConfigLua = ''
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
          expandLines = false;
          layouts = [
            {
              elements = [
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
              position = "bottom";
              size = 10;
            }
            {
              elements = [
                {
                  id = "scopes";
                  size = 1;
                }
              ];
              position = "bottom";
              size = 10;
            }
            {
              elements = [
                {
                  id = "repl";
                  size = 1;
                }
              ];
              position = "bottom";
              size = 10;
            }
          ];
        };
        dap-virtual-text = {
          enable = false;
          enabledCommands = true;
        };
      };
    };

    keymaps = [
      {
        action.__raw =
          # lua
          ''
            function()
              require('dap').continue()
            end
          '';
        key = "<leader>dc";
        options = {
          desc = "Continue";
        };
        mode = [
          "n"
        ];
      }
      {
        action.__raw =
          # lua
          ''
            function()
              local render = require("dapui.config").render
              render.max_type_length = (render.max_type_length == nil) and 0 or nil
              require("dapui").update_render(render)
            end
          '';
        key = "<leader>dut";
        options = {
          desc = " toggle types";
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
        key = "F5";
        options = {
          desc = "Step over";
        };
        mode = [
          "n"
        ];
      }
      {
        action.__raw =
          # lua
          ''
            function()
              require('dap').step_into()
            end
          '';
        key = "F6";
        options = {
          desc = "Step Into";
        };
        mode = [
          "n"
        ];
      }
      {
        action.__raw =
          # lua
          ''
            function()
              require('dap').step_out()
            end
          '';
        key = "F7";
        options = {
          desc = "Step Out";
        };
        mode = [
          "n"
        ];
      }
      {
        action.__raw =
          # lua
          ''
            function()
              require('dap').pause()
            end
          '';
        key = "<leader>dp";
        options = {
          desc = "Pause";
        };
        mode = [
          "n"
        ];
      }
      {
        action.__raw =
          # lua
          ''
            function()
              require('dap').toggle_breakpoint()
            end
          '';
        key = "<leader>db";
        options = {
          desc = "Toggle Breakpoint";
        };
        mode = [
          "n"
        ];
      }
      {
        action.__raw =
          # lua
          ''
            function()
            	require('dap').set_breakpoint(vim.fn.input('Breakpoint condition: '))
            end
          '';
        key = "<leader>dB";
        options = {
          desc = "Breakpoint (conditional)";
        };
        mode = [
          "n"
        ];
      }
      {
        action.__raw =
          # lua
          ''
            function()
              require('dap').repl.toggle()
            end
          '';
        key = "<leader>dR";
        options = {
          desc = "Toggle REPL";
        };
        mode = [
          "n"
        ];
      }
      {
        action.__raw =
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
        options = {
          desc = "Restart Debugger";
        };
        mode = [
          "n"
        ];
      }
      {
        action.__raw =
          # lua
          ''
            function()
              require('dap').run_last()
            end
          '';
        key = "<leader>dl";
        options = {
          desc = "Run Last";
        };
        mode = [
          "n"
        ];
      }
      {
        action.__raw =
          # lua
          ''
            function()
              require('dap').session()
            end
          '';
        key = "<leader>ds";
        options = {
          desc = "Session";
        };
        mode = [
          "n"
        ];
      }
      {
        action.__raw =
          # lua
          ''
            function()
              require('dap').terminate()
            end
          '';
        key = "<leader>dt";
        options = {
          desc = "Terminate";
        };
        mode = [
          "n"
        ];
      }
      {
        action.__raw =
          # lua
          ''
            function()
              require('dap.ui.widgets').hover()
            end
          '';
        key = "<leader>dw";
        options = {
          desc = "Hover Widget";
        };
        mode = [
          "n"
        ];
      }
      {
        action.__raw =
          # lua
          ''
            function()
              require('dap').run_to_cursor()
            end
          '';
        key = "<leader>dC";
        options = {
          desc = "Run all lines up to cursor";
        };
        mode = [
          "n"
        ];
      }
      {
        action.__raw =
          # lua
          ''
            function()
              require('dapui').eval(nil, { enter = true })
            end
          '';
        key = "<leader>?";
        options = {
          desc = "Evaluate value under cursor";
        };
        mode = [
          "n"
        ];
      }
      {
        action.__raw =
          # lua
          ''
            function()
              require('dapui').toggle()
            end
          '';
        key = "<leader>du";
        options = {
          desc = "Toggle UI";
        };
        mode = [
          "n"
        ];
      }
      {
        action.__raw =
          # lua
          ''
            function()
              require('dapui').eval()
            end
          '';
        key = "<leader>de";
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
