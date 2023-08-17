{
  programs.nixvim = {
    plugins.dap = {
      enable = true;
      extensions = {
        dap-ui.enable = true;
        dap-virtual-text.enable = true;
      };
    };
    # TODO: Use keymaps i.e. "<cmd>lua require('dap-go').debug_test()<CR>"
    extraConfigLua =
      # lua
      ''
        vim.keymap.set('n', '<leader>dc', function() require('dap').continue() end)
        vim.keymap.set('n', '<leader>dO', function() require('dap').step_over() end)
        vim.keymap.set('n', '<leader>di', function() require('dap').step_into() end)
        vim.keymap.set('n', '<leader>do', function() require('dap').step_out() end)
        vim.keymap.set('n', '<Leader>db', function() require('dap').toggle_breakpoint() end)
        vim.keymap.set('n', '<Leader>dB', function() require('dap').set_breakpoint() end)
        vim.keymap.set('n', '<Leader>dlp', function() require('dap').set_breakpoint(nil, nil, vim.fn.input('Log point message: ')) end)
        vim.keymap.set('n', '<Leader>dr', function() require('dap').repl.open() end)
        vim.keymap.set('n', '<Leader>dl', function() require('dap').run_last() end)
        vim.keymap.set({'n', 'v'}, '<Leader>dh', function()
          require('dap.ui.widgets').hover()
        end)
        vim.keymap.set({'n', 'v'}, '<Leader>dp', function()
          require('dap.ui.widgets').preview()
        end)
        vim.keymap.set('n', '<Leader>df', function()
          local widgets = require('dap.ui.widgets')
          widgets.centered_float(widgets.frames)
        end)
        vim.keymap.set('n', '<Leader>ds', function()
          local widgets = require('dap.ui.widgets')
          widgets.centered_float(widgets.scopes)
        end)
      '';
  };
}
