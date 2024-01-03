{config, ...}: {
  programs.git = {
    enable = true;
    userName = "Haseeb Majid";
    userEmail = "hello@haseebmajid.dev";

    signing = {
      signByDefault = true;
      key = "D528 BD50 F4E9 F031 AACB 1F7A 9833 E49C 848D 6C90";
    };

    extraConfig = {
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
        activeBorderColor = ["#${config.colorscheme.colors.base0B}" "bold"];
        inactiveBorderColor = ["#${config.colorscheme.colors.base05}"];
        optionsTextColor = ["#${config.colorscheme.colors.base0D}"];
        selectedLineBgColor = ["#${config.colorscheme.colors.base02}"];
        selectedRangeBgColor = ["#${config.colorscheme.colors.base02}"];
        cherryPickedCommitBgColor = ["#${config.colorscheme.colors.base0C}"];
        cherryPickedCommitFgColor = ["#${config.colorscheme.colors.base0D}"];
        unstagedChangesColor = ["#${config.colorscheme.colors.base08}"];
      };
      customCommands = [
        {
          key = "W";
          command = "git commit -m '{{index .PromptResponses 0}}' --no-verify";
          description = "commit without verification";
          context = "global";
          subprocess = true;
        }
        {
          key = "S";
          command = "git commit -m '{{index .PromptResponses 0}}' --no-gpg-sign";
          description = "commit without gpg signing";
          context = "global";
          subprocess = true;
        }
      ];
    };
  };
}
