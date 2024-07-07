{
  programs.nixvim = {
    plugins = {
      trouble = {
        enable = true;
      };
    };

    keymaps = [
      {
        action.__raw =
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
        options = {
          desc = "Next quickfix item";
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
        options = {
          desc = "Previous quickfix item";
        };
        mode = [
          "n"
        ];
      }
      {
        action = "<cmd>Trouble diagnostics toggle filter.buf=0<cr>";
        key = "<leader>xx";
        options = {
          desc = "Document diagnostics";
        };
        mode = [
          "n"
        ];
      }
      {
        action = "<cmd>Trouble diagnostics toggle<cr>";
        key = "<leader>xX";
        options = {
          desc = "Workplace diagnostics";
        };
        mode = [
          "n"
        ];
      }
      {
        action = "<cmd>Trouble loclist toggle<cr>";
        key = "<leader>xL";
        options = {
          desc = "Location list";
        };
        mode = [
          "n"
        ];
      }
      {
        action = "<cmd>Trouble qflist toggle<cr>";
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
