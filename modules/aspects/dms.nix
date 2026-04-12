_: {
  den.aspects.dms = {
    homeManager =
      {
        pkgs,
        config,
        lib,
        ...
      }:
      let
        colors = config.lib.stylix.colors.withHashtag;
        stylixColorTheme = {
          dark = {
            name = "Stylix generated dark theme (Catppuccin-inspired)";
            primary = colors.base0E;
            primaryText = "#11111b";
            primaryContainer = colors.base0C;
            secondary = colors.base09;
            surface = colors.base00;
            surfaceText = colors.base05;
            surfaceVariant = colors.base02;
            surfaceVariantText = colors.base07;
            surfaceTint = colors.base0E;
            background = colors.base00;
            backgroundText = colors.base05;
            outline = colors.base04;
            surfaceContainer = colors.base01;
            surfaceContainerHigh = colors.base02;
            surfaceContainerHighest = colors.base03;
            error = colors.base08;
            warning = colors.base0A;
            info = colors.base0C;
          };
          light = {
            name = "Stylix generated light theme";
            primary = colors.base0D;
            primaryText = colors.base07;
            primaryContainer = colors.base0C;
            secondary = colors.base0E;
            surface = colors.base06;
            surfaceText = colors.base01;
            surfaceVariant = colors.base07;
            surfaceVariantText = colors.base02;
            surfaceTint = colors.base0D;
            background = colors.base07;
            backgroundText = colors.base00;
            outline = colors.base04;
            surfaceContainer = colors.base06;
            surfaceContainerHigh = colors.base05;
            surfaceContainerHighest = colors.base04;
            error = colors.base08;
            warning = colors.base0A;
            info = colors.base0C;
          };
        };
      in
      {
        home.packages = with pkgs; [
          hicolor-icon-theme
          adwaita-icon-theme
        ];

        programs.dankMaterialShell = {
          enable = true;
          systemd.enable = true;
          enableSystemMonitoring = true;
          enableVPN = true;
          enableDynamicTheming = true;
          enableAudioWavelength = true;
          enableCalendarEvents = false;

          default.settings = lib.mkMerge [
            {
              currentThemeName = "custom";
              customThemeFile = pkgs.writeText "dankMaterialShell-stylix-theme.json" (
                builtins.toJSON stylixColorTheme
              );
              showWorkspaceIndex = true;
              showWorkspaceApps = true;
              maxWorkspaceIcons = 3;
              workspacesPerMonitor = true;
              showSeconds = true;
              weatherLocation = "London, England";
              weatherCoordinates = "51.4893335,-0.1440551";
              monoFontFamily = "MonoLisa";
              dankBarLeftWidgets = [
                "workspaceSwitcher"
                {
                  id = "focusedWindow";
                  enabled = false;
                }
              ];
              dankBarCenterWidgets = [
                {
                  id = "music";
                  enabled = false;
                }
                {
                  id = "clock";
                  enabled = true;
                }
                {
                  id = "idleInhibitor";
                  enabled = true;
                }
                {
                  id = "weather";
                  enabled = false;
                }
              ];
              dankBarRightWidgets = [
                {
                  id = "systemTray";
                  enabled = true;
                }
                {
                  id = "clipboard";
                  enabled = true;
                }
                {
                  id = "cpuUsage";
                  enabled = true;
                }
                {
                  id = "notificationButton";
                  enabled = true;
                }
                {
                  id = "privacyIndicator";
                  enabled = true;
                }
                {
                  id = "controlCenterButton";
                  enabled = true;
                }
              ];
            }
          ];
        };
      };
  };
}
