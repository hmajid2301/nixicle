{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
with lib.nixicle;
let
  cfg = config.desktops.addons.dms;

  # Generate color theme from Stylix colors
  # Based on: https://github.com/nix-community/stylix/pull/1932
  stylixColorTheme =
    let
      colors = config.lib.stylix.colors.withHashtag;
    in
    {
      dark = {
        name = "Stylix generated dark theme";
        primary = colors.base0D;
        primaryText = colors.base00;
        primaryContainer = colors.base0C;
        secondary = colors.base0E;
        surface = colors.base01;
        surfaceText = colors.base05;
        surfaceVariant = colors.base02;
        surfaceVariantText = colors.base04;
        surfaceTint = colors.base0D;
        background = colors.base00;
        backgroundText = colors.base05;
        outline = colors.base03;
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
  options.desktops.addons.dms = {
    enable = mkEnableOption "Enable DankMaterialShell";

    settings = mkOption {
      type = types.attrs;
      default = { };
      description = "Additional settings to merge with the default configuration";
    };
  };

  config = mkIf cfg.enable {
    home.packages = [
      pkgs.hicolor-icon-theme
      pkgs.adwaita-icon-theme
    ];

    programs.dankMaterialShell = {
      enable = true;
      systemd.enable = true;

      default.settings = mkMerge [
        {
          currentThemeName = "custom";
          customThemeFile = pkgs.writeText "dankMaterialShell-stylix-theme.json" (
            builtins.toJSON stylixColorTheme
          );

          showWorkspaceIndex = true;
          "showWorkspaceApps" = true;
          "maxWorkspaceIcons" = 3;
          "workspacesPerMonitor" = true;

          "showSeconds" = true;
          "weatherLocation" = "London, England";
          "weatherCoordinates" = "51.4893335,-0.1440551";

          "monoFontFamily" = "MonoLisa";

          "dankBarLeftWidgets" = [
            "workspaceSwitcher"
            {
              "id" = "focusedWindow";
              "enabled" = false;
            }
          ];
          "dankBarCenterWidgets" = [
            {
              "id" = "music";
              "enabled" = false;
            }
            {
              "id" = "clock";
              "enabled" = true;
            }
            {
              "id" = "idleInhibitor";
              "enabled" = true;
            }
            {
              "id" = "weather";
              "enabled" = false;
            }
          ];
          "dankBarRightWidgets" = [
            {
              "id" = "systemTray";
              "enabled" = true;
            }
            {
              "id" = "clipboard";
              "enabled" = true;
            }
            {
              "id" = "cpuUsage";
              "enabled" = true;
            }
            {
              "id" = "notificationButton";
              "enabled" = true;
            }
            {
              "id" = "privacyIndicator";
              "enabled" = true;
            }
            {
              "id" = "controlCenterButton";
              "enabled" = true;
            }
          ];
        }

        cfg.settings
      ];
    };
  };
}
