{pkgs, ...}: {
  programs.nixvim = {
    extraPlugins = with pkgs.vimPlugins; [
      vim-pencil
      render-markdown-nvim
    ];

    keymaps = [
      {
        action = "<cmd> Telescope find_files search_dirs={\"~/second-brain\"} <CR>";
        key = "<leader>of";
        options = {
          desc = "Find files in second brain";
        };
        mode = [
          "n"
        ];
      }
      {
        action = "<cmd> Telescope live_grep search_dirs={\"~/second-brain\"} <CR>";
        key = "<leader>og";
        options = {
          desc = "Search contents in second brain";
        };
        mode = [
          "n"
        ];
      }
    ];

    extraConfigLua = ''
      require('render-markdown').setup({
      })
    '';

    plugins = {
      twilight.enable = true;
      zen-mode.enable = true;
      # headlines.enable = true;
    };
  };
}
