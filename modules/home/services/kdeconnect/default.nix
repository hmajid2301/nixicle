{
  config,
  pkgs,
  lib,
  ...
}:
with lib;
with lib.nixicle;
let
  cfg = config.services.nixicle.kdeconnect;
in
{
  options.services.nixicle.kdeconnect = with types; {
    enable = mkBoolOpt false "Whether or not to manage kdeconnect";
  };

  config = mkIf cfg.enable {
    xdg.desktopEntries = {
      "org.kde.kdeconnect.sms" = {
        exec = "";
        name = "KDE Connect SMS";
        settings.NoDisplay = "true";
      };
      "org.kde.kdeconnect.nonplasma" = {
        exec = "";
        name = "KDE Connect Indicator";
        settings.NoDisplay = "true";
      };
      "org.kde.kdeconnect.app" = {
        exec = "";
        name = "KDE Connect";
        settings.NoDisplay = "true";
      };
    };

    home.sessionVariables =
      {
        QT_QPA_PLATFORMTHEME = "qt5ct";
      }
      // (lib.optionalAttrs config.stylix.enable {
        QT_STYLE_OVERRIDE = "kvantum";
      });

    qt = {
      enable = true;
      platformTheme.name = mkIf config.stylix.enable "kvantum";
      style.name = mkIf config.stylix.enable "kvantum";
    };

    xdg.configFile.kdeglobals = mkIf config.stylix.enable {
      source =
        let
          themePackage = builtins.head (
            builtins.filter (
              p: builtins.match ".*stylix-kde-theme.*" (builtins.baseNameOf p) != null
            ) config.home.packages
          );
          colorSchemeSlug = lib.concatStrings (
            lib.filter lib.isString (builtins.split "[^a-zA-Z]" config.lib.stylix.colors.scheme)
          );
        in
        "${themePackage}/share/color-schemes/${colorSchemeSlug}.colors";
    };

    services.kdeconnect = {
      enable = true;
      indicator = true;
    };
  };
}
