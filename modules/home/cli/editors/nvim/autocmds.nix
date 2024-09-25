{
  programs.nixvim = {
    autoGroups = {
      highlight_yank.clear = true;
      # close_with_q.clear = true;
    };

    autoCmd = [
      {
        event = ["TextYankPost"];
        group = "highlight_yank";
        desc = "Highlight yanked content";
        callback = {__raw = "function() vim.highlight.on_yank() end";};
      }
      {
        event = [
          "BufWritePre"
        ];
        pattern = [
          "*.templ"
        ];
        callback = {
          __raw = ''
             function()
                if vim.bo.filetype == "templ" then
                    local bufnr = vim.api.nvim_get_current_buf()
                    local filename = vim.api.nvim_buf_get_name(bufnr)
                    local cmd = "templ fmt " .. vim.fn.shellescape(filename)

                    vim.fn.jobstart(cmd, {
                        on_exit = function()
                            -- Reload the buffer only if it's still the current buffer
                            if vim.api.nvim_get_current_buf() == bufnr then
                                vim.cmd('e!')
                            end
                        end,
                    })
                else
                    vim.lsp.buf.format()
                end
            end
          '';
        };
      }
      # {
      #   event = ["FileType"];
      #   group = "close_with_q";
      #   desc = "Close some panes with q";
      #   pattern = [
      #     "PlenaryTestPopup"
      #     "help"
      #     "lspinfo"
      #     "man"
      #     "notify"
      #     "qf"
      #     "spectre_panel"
      #     "tsplayground"
      #     "neotest-output"
      #     "checkhealth"
      #     "neotest-summary"
      #     "neotest-output-panel"
      #   ];
      #   callback = {
      #     __raw =
      #       # lua
      #       ''
      #         function()
      #         	vim.bo[event.buf].buflisted = false
      #         	vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = event.buf, silent = true })
      #         end
      #       '';
      #   };
      # }
    ];
  };
}
