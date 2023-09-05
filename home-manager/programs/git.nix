{ config, ... }: {
  programs.git = {
    enable = true;
    userName = "Haseeb Majid";
    userEmail = "hello@haseebmajid.dev";

    #signing = {
    #  signByDefault = true;
    #  key = "F04F 743A 24CD 81B6 28A2  0667 CD20 E737 3D83 B71C";
    #};

    extraConfig = {
      gpg.format = "ssh";

      core = {
        editor = "nvim";
        pager = "delta";
      };

      color = {
        ui = true;
      };

      interactive = {
        diffFitler = "delta --color-only";
      };

      delta = {
        enable = true;
        navigate = true;
        light = false;
        side-by-side = false;
        options.syntax-theme = "catppuccin";
      };

      pull = {
        ff = "only";
      };

      push = {
        default = "current";
        autoSetupRemote = true;
      };

      init = {
        defaultBranch = "init";
      };
    };
  };

  programs.lazygit = {
    enable = true;
    settings = {
      git = {
        paging = {
          colorArg = "always";
          pager = "delta --color-only --dark --paging=never";
          useConfig = false;
        };
      };
      gui.theme = {
        lightTheme = false;
        activeBorderColor = [ "#${config.colorscheme.colors.base0B}" "bold" ];
        inactiveBorderColor = [ "#${config.colorscheme.colors.base05}" ];
        optionsTextColor = [ "#${config.colorscheme.colors.base0D}" ];
        selectedLineBgColor = [ "#${config.colorscheme.colors.base02}" ];
        selectedRangeBgColor = [ "#${config.colorscheme.colors.base02}" ];
        cherryPickedCommitBgColor = [ "#${config.colorscheme.colors.base0C}" ];
        cherryPickedCommitFgColor = [ "#${config.colorscheme.colors.base0D}" ];
        unstagedChangesColor = [ "#${config.colorscheme.colors.base08}" ];
      };
      customCommands = [
        {
          key = "W";
          command = "git commit -m '{{index .PromptResponses 0}}' --no-verify";
          description = "ignore commit hooks";
          context = "global";
          subprocess = true;
        }
      ];
    };
  };
}
