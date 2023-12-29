{
  programs.nixvim = {
    plugins = {
      trouble = {
        enable = true;
        autoClose = true;
      };
    };

    plugins.which-key.registrations = {
      "<leader>x" = "+quickfix";
    };

    keymaps = [
      {
        action =
          # lua
          ''
            function()
              if require("trouble").is_open() then
                require("trouble").next({ skip_groups = true, jump = true })
              else
                local ok, err = pcall(vim.cmd.cnext)
                if not ok then
                  vim.notify(err, vim.log.levels.ERROR)
                end
              end
            end
          '';
        key = "]q";
        lua = true;
        options = {
          desc = "Next quickfix item";
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
            	if require("trouble").is_open() then
            		require("trouble").previous({ skip_groups = true, jump = true })
            	else
            		local ok, err = pcall(vim.cmd.cprev)
            		if not ok then
            			vim.notify(err, vim.log.levels.ERROR)
            		end
            	end
            end
          '';
        key = "[q";
        lua = true;
        options = {
          desc = "Previous quickfix item";
        };
        mode = [
          "n"
        ];
      }
      {
        action = "<cmd>TroubleToggle document_diagnostics<cr>";
        key = "<leader>xx";
        options = {
          desc = "Document diagnostics";
        };
        mode = [
          "n"
        ];
      }
      {
        action = "<cmd>TroubleToggle workspace_diagnostics<cr>";
        key = "<leader>xX";
        options = {
          desc = "Workplace diagnostics";
        };
        mode = [
          "n"
        ];
      }
      {
        action = "<cmd>TroubleToggle loclist<cr>";
        key = "<leader>xL";
        options = {
          desc = "Location list";
        };
        mode = [
          "n"
        ];
      }
      {
        action = "<cmd>TroubleToggle quickfix<cr>";
        key = "<leader>xQ";
        options = {
          desc = "Quickfix list";
        };
        mode = [
          "n"
        ];
      }
      {
        action = "<cmd>TroubleToggle quickfix<cr>";
        key = "<leader>xQ";
        options = {
          desc = "Quickfix list";
        };
        mode = [
          "n"
        ];
      }
      {
        action = "<cmd>TodoTrouble<cr>";
        key = "<leader>xt";
        options = {
          desc = "Todo (trouble)";
        };
        mode = [
          "n"
        ];
      }
      {
        action = "<cmd>TodoTelescope<cr>";
        key = "<leader>ft";
        options = {
          desc = "Find Todos";
        };
        mode = [
          "n"
        ];
      }
    ];
  };
}
