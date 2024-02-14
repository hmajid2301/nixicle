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
