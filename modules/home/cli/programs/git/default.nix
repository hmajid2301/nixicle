{
  config,
  lib,
  ...
}:
with lib;
with lib.nixicle; let
  cfg = config.cli.programs.git;
  inherit (config.colorScheme) palette;

  rewriteURL =
    lib.mapAttrs' (key: value: {
      name = "url.${key}";
      value = {insteadOf = value;};
    })
    cfg.urlRewrites;
in {
  options.cli.programs.git = with types; {
    enable = mkBoolOpt false "Whether or not to enable git.";
    email = mkOpt (nullOr str) "hello@haseebmajid.dev" "The email to use with git.";
    urlRewrites = mkOpt (attrsOf str) {} "url we need to rewrite i.e. ssh to http";
  };

  config = mkIf cfg.enable {
    programs.git = {
      enable = true;
      userName = "Haseeb Majid";
      userEmail = cfg.email;

      signing = {
        signByDefault = true;
        key = "D528 BD50 F4E9 F031 AACB 1F7A 9833 E49C 848D 6C90";
      };

      extraConfig =
        {
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
        }
        // rewriteURL;
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
          activeBorderColor = ["#${palette.base0B}" "bold"];
          inactiveBorderColor = ["#${palette.base05}"];
          optionsTextColor = ["#${palette.base0D}"];
          selectedLineBgColor = ["#${palette.base02}"];
          selectedRangeBgColor = ["#${palette.base02}"];
          cherryPickedCommitBgColor = ["#${palette.base0C}"];
          cherryPickedCommitFgColor = ["#${palette.base0D}"];
          unstagedChangesColor = ["#${palette.base08}"];
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
  };
}
