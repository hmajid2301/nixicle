{
  pkgs,
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.desktops.addons.qt;
in {
  options.desktops.addons.qt = {
    enable = mkEnableOption "enable qt theme management";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      libsForQt5.qtstyleplugin-kvantum
      (catppuccin-kvantum.override {
        accent = "Mauve";
        variant = "Mocha";
      })
    ];
    home.sessionVariables = {QT_STYLE_OVERRIDE = "kvantum";};

    xdg.configFile."Kvantum/kvantum.kvconfig".source = (pkgs.formats.ini {}).generate "kvantum.kvconfig" {
      General.theme = "Catppuccin-Mocha-Mauve";
    };
  };
}
