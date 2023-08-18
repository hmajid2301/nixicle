{pkgs, ...}: {
  imports = [
    ./editor/telescope.nix
    ./editor/trouble.nix
  ];

  programs.nixvim = {
    plugins = {
      auto-save = {
        enable = true;
      };

      illuminate = {
        enable = true;
        delay = 200;
        largeFileOverrides = {
          largeFileCutoff = 2000;
        };
      };

      nvim-colorizer = {
        enable = true;
      };

      todo-comments = {
        enable = true;
      };

      toggleterm = {
        enable = true;
        direction = "float";
      };

      which-key = {
        enable = true;
      };
    };

    extraPlugins = with pkgs.vimPlugins; [better-escape-nvim];
    extraConfigLua =
      # TODO: Move keymaps to specific files
      #  - test
      #  - debug
      #  - telescope
      #  - editor
      # lua
      ''
        require("which-key").register({
          mode = {"n", "v"},
          ["<leader>f"] = { name = "+file/find" },
          ["<leader>g"] = { name = "+git" },
          ["<leader>d"] = { name = "+debug" },
          ["<leader>t"] = { name = "+test" },
          ["<leader>x"] = { name = "+quickfix" },
          ["<leader>s"] = { name = "+surround" },
        })

        require("better_escape").setup()
      '';
  };
}
