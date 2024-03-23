{
  pkgs,
  config,
  lib,
  ...
}:
with lib;
with lib.nixicle; let
  cfg = config.cli.programs.k8s;
  inherit (config.colorScheme) palette;
in {
  options.cli.programs.k8s = with types; {
    enable = mkBoolOpt false "Whether or not to manage kubernetes";
  };

  config = mkIf cfg.enable {
    programs = {
      k9s = {
        enable = true;
        skins.skin = {
          k9s = {
            body = {
              fgColor = "#${palette.base05}";
              bgColor = "#${palette.base00}";
              logoColor = "#${palette.base0E}";
            };
            prompt = {
              fgColor = "#${palette.base05}";
              bgColor = "#${palette.base01}";
              suggestColor = "#${palette.base0D}";
            };
            info = {
              fgColor = "#${palette.base09}";
              sectionColor = "#${palette.base05}";
            };
            dialog = {
              fgColor = "#${palette.base0A}";
              bgColor = "#9399b2";
              buttonFgColor = "#${palette.base00}";
              buttonBgColor = "#7f849c";
              buttonFocusFgColor = "#${palette.base00}";
              buttonFocusBgColor = "#f5c2e7";
              labelFgColor = "#${palette.base06}";
              fieldFgColor = "#${palette.base05}";
            };
            frame = {
              border = {
                fgColor = "#${palette.base0E}";
                focusColor = "#b4befe";
              };
              menu = {
                fgColor = "#${palette.base05}";
                keyColor = "#${palette.base0D}";
                numKeyColor = "#eba0ac";
              };
              crumbs = {
                fgColor = "#${palette.base00}";
                bgColor = "#eba0ac";
                activeColor = "#${palette.base0F}";
              };
              status = {
                newColor = "#${palette.base0D}";
                modifyColor = "#b4befe";
                addColor = "#${palette.base0B}";
                pendingColor = "#${palette.base09}";
                errorColor = "#${palette.base08}";
                highlightColor = "#89dceb";
                killColor = "#${palette.base0E}";
                completedColor = "#6c7086";
              };
              title = {
                fgColor = "#94e2d5";
                bgColor = "#${palette.base00}";
                highlightColor = "#f5c2e7";
                counterColor = "#${palette.base0A}";
                filterColor = "#${palette.base0B}";
              };
            };
            views = {
              charts = {
                bgColor = "#${palette.base00}";
                chartBgColor = "#${palette.base00}";
                dialBgColor = "#${palette.base00}";
                defaultDialColors = ["#${palette.base0B}" "#${palette.base08}"];
                defaultChartColors = ["#${palette.base0B}" "#${palette.base08}"];
                resourceColors = {
                  cpu = ["#${palette.base0E}" "#${palette.base0D}"];
                  mem = ["#${palette.base0A}" "#${palette.base09}"];
                };
              };
              table = {
                fgColor = "#${palette.base05}";
                bgColor = "#${palette.base00}";
                cursorFgColor = "#313244";
                cursorBgColor = "#45475a";
                markColor = "#${palette.base06}";
                header = {
                  fgColor = "#${palette.base0A}";
                  bgColor = "#${palette.base00}";
                  sorterColor = "#89dceb";
                };
              };
              xray = {
                fgColor = "#${palette.base05}";
                bgColor = "#${palette.base00}";
                cursorColor = "#45475a";
                cursorTextColor = "#${palette.base00}";
                graphicColor = "#f5c2e7";
              };
              yaml = {
                keyColor = "#${palette.base0D}";
                colonColor = "#a6adc8";
                valueColor = "#${palette.base05}";
              };
              logs = {
                fgColor = "#${palette.base05}";
                bgColor = "#${palette.base00}";
                indicator = {
                  fgColor = "#b4befe";
                  bgColor = "#${palette.base00}";
                };
              };
            };
            help = {
              fgColor = "#${palette.base05}";
              bgColor = "#${palette.base00}";
              sectionColor = "#${palette.base0B}";
              keyColor = "#${palette.base0D}";
              numKeyColor = "#eba0ac";
            };
          };
        };
      };
    };

    home.packages = with pkgs; [
      kubectl
      kubectx
      kubelogin
      kubelogin-oidc
      stern
      kubernetes-helm
    ];
  };
}
