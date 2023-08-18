{pkgs, ...}: {
  imports = [
    ./editor/telescope.nix
    ./editor/trouble.nix
  ];

  programs.nixvim = {
    clipboard.providers.wl-copy.enable = true;

    plugins = {
      # auto-save = {
      #   enable = true;
      #   debounceDelay = 5000;
      #   extraOptions = {
      #     trigger_events = ["TextChanged"];
      #   };
      # };

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

      indent-blankline = {
        enable = true;
        filetypeExclude = [
          "help"
          "terminal"
          "lazy"
          "lspinfo"
          "TelescopePrompt"
          "TelescopeResults"
          "Alpha"
          ""
        ];
        showTrailingBlanklineIndent = false;
        showFirstIndentLevel = false;
        showCurrentContext = true;
        showCurrentContextStart = true;
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
      # lua
      ''
        require("which-key").register({
          mode = {"n", "v"},
          ["<leader>f"] = { name = "+file/find" },
        })

        require("better_escape").setup()
      '';
  };
}
