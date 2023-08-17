{pkgs, ...}: {
  programs.nixvim = {
    plugins = {
      trouble = {
        enable = true;
        autoClose = true;
      };
    };

    extraConfigLua =
      # lua
      ''
        require("which-key").register({
          ["<leader>x"] = { name = "+quickfix" },
        })

        -- Trouble
        vim.keymap.set('n', '[q',
          function()
            if require("trouble").is_open() then
              require("trouble").previous({ skip_groups = true, jump = true })
            else
              local ok, err = pcall(vim.cmd.cprev)
              if not ok then
                vim.notify(err, vim.log.levels.ERROR)
              end
            end
          end,
          desc = "Previous trouble/quickfix item"
        )

        vim.keymap.set('n', ']q',
          function()
            if require("trouble").is_open() then
              require("trouble").next({ skip_groups = true, jump = true })
            else
              local ok, err = pcall(vim.cmd.cnext)
              if not ok then
                vim.notify(err, vim.log.levels.ERROR)
              end
            end
          end,
          desc = "Next trouble/quickfix item"
        )
      '';

    maps = {
      normal = {
        "<leader>xx" = {
          action = "<cmd>TroubleToggle document_diagnostics<cr>";
          desc = "Document Diagnostics";
        };
        "<leader>xX" = {
          action = "<cmd>TroubleToggle workspace_diagnostics<cr>";
          desc = "Workspace Diagnostics";
        };
        "<leader>xL" = {
          action = "<cmd>TroubleToggle loclist<cr>";
          desc = "Location List";
        };
        "<leader>xQ" = {
          action = "<cmd>TroubleToggle quickfix<cr>";
          desc = "Quickfix List";
        };
        "<leader>xt" = {
          action = "<cmd>TodoTrouble<cr>";
          desc = "Todo (trouble)";
        };
        "<leader>ft" = {
          action = "<cmd>TodoTelescope<cr>";
          desc = "Find Todos";
        };
      };
    };
  };
}
