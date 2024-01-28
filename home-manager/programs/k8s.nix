{
  pkgs,
  config,
  ...
}: {
  programs = {
    k9s = {
      enable = true;
      skins.skin = {
        k9s = {
          body = {
            fgColor = "#${config.colorscheme.colors.base05}";
            bgColor = "#${config.colorscheme.colors.base00}";
            logoColor = "#${config.colorscheme.colors.base0E}";
          };
          prompt = {
            fgColor = "#${config.colorscheme.colors.base05}";
            bgColor = "#${config.colorscheme.colors.base01}";
            suggestColor = "#${config.colorscheme.colors.base0D}";
          };
          info = {
            fgColor = "#${config.colorscheme.colors.base09}";
            sectionColor = "#${config.colorscheme.colors.base05}";
          };
          dialog = {
            fgColor = "#${config.colorscheme.colors.base0A}";
            bgColor = "#9399b2";
            buttonFgColor = "#${config.colorscheme.colors.base00}";
            buttonBgColor = "#7f849c";
            buttonFocusFgColor = "#${config.colorscheme.colors.base00}";
            buttonFocusBgColor = "#f5c2e7";
            labelFgColor = "#${config.colorscheme.colors.base06}";
            fieldFgColor = "#${config.colorscheme.colors.base05}";
          };
          frame = {
            border = {
              fgColor = "#${config.colorscheme.colors.base0E}";
              focusColor = "#b4befe";
            };
            menu = {
              fgColor = "#${config.colorscheme.colors.base05}";
              keyColor = "#${config.colorscheme.colors.base0D}";
              numKeyColor = "#eba0ac";
            };
            crumbs = {
              fgColor = "#${config.colorscheme.colors.base00}";
              bgColor = "#eba0ac";
              activeColor = "#${config.colorscheme.colors.base0F}";
            };
            status = {
              newColor = "#${config.colorscheme.colors.base0D}";
              modifyColor = "#b4befe";
              addColor = "#${config.colorscheme.colors.base0B}";
              pendingColor = "#${config.colorscheme.colors.base09}";
              errorColor = "#${config.colorscheme.colors.base08}";
              highlightColor = "#89dceb";
              killColor = "#${config.colorscheme.colors.base0E}";
              completedColor = "#6c7086";
            };
            title = {
              fgColor = "#94e2d5";
              bgColor = "#${config.colorscheme.colors.base00}";
              highlightColor = "#f5c2e7";
              counterColor = "#${config.colorscheme.colors.base0A}";
              filterColor = "#${config.colorscheme.colors.base0B}";
            };
          };
          views = {
            charts = {
              bgColor = "#${config.colorscheme.colors.base00}";
              chartBgColor = "#${config.colorscheme.colors.base00}";
              dialBgColor = "#${config.colorscheme.colors.base00}";
              defaultDialColors = ["#${config.colorscheme.colors.base0B}" "#${config.colorscheme.colors.base08}"];
              defaultChartColors = ["#${config.colorscheme.colors.base0B}" "#${config.colorscheme.colors.base08}"];
              resourceColors = {
                cpu = ["#${config.colorscheme.colors.base0E}" "#${config.colorscheme.colors.base0D}"];
                mem = ["#${config.colorscheme.colors.base0A}" "#${config.colorscheme.colors.base09}"];
              };
            };
            table = {
              fgColor = "#${config.colorscheme.colors.base05}";
              bgColor = "#${config.colorscheme.colors.base00}";
              cursorFgColor = "#313244";
              cursorBgColor = "#45475a";
              markColor = "#${config.colorscheme.colors.base06}";
              header = {
                fgColor = "#${config.colorscheme.colors.base0A}";
                bgColor = "#${config.colorscheme.colors.base00}";
                sorterColor = "#89dceb";
              };
            };
            xray = {
              fgColor = "#${config.colorscheme.colors.base05}";
              bgColor = "#${config.colorscheme.colors.base00}";
              cursorColor = "#45475a";
              cursorTextColor = "#${config.colorscheme.colors.base00}";
              graphicColor = "#f5c2e7";
            };
            yaml = {
              keyColor = "#${config.colorscheme.colors.base0D}";
              colonColor = "#a6adc8";
              valueColor = "#${config.colorscheme.colors.base05}";
            };
            logs = {
              fgColor = "#${config.colorscheme.colors.base05}";
              bgColor = "#${config.colorscheme.colors.base00}";
              indicator = {
                fgColor = "#b4befe";
                bgColor = "#${config.colorscheme.colors.base00}";
              };
            };
          };
          help = {
            fgColor = "#${config.colorscheme.colors.base05}";
            bgColor = "#${config.colorscheme.colors.base00}";
            sectionColor = "#${config.colorscheme.colors.base0B}";
            keyColor = "#${config.colorscheme.colors.base0D}";
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
}
