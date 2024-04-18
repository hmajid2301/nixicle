{
  config,
  pkgs,
  lib,
  ...
}:
with lib;
with lib.nixicle; let
  cfg = config.desktops.addons.rofi;
in {
  options.desktops.addons.rofi = {
    enable = mkEnableOption "Enable rofi app manager";
    package = mkPackageOpt pkgs.rofi-wayland "Package to use for rofi";
  };

  config = mkIf cfg.enable {
    programs.rofi = {
      enable = true;
      package = cfg.package;
      catppuccin.enable = true;
      extraConfig = {
        modi = "run,drun,window";
        show-icons = true;
        drun-display-format = "{icon} {name}";
        location = 0;
        disable-history = false;
        hide-scrollbar = true;
        display-drun = "   Apps ";
        display-run = "   Run ";
        display-window = " 﩯  Window";
        display-Network = " 󰤨  Network";
        sidebar-mode = true;
        font = "MonoLisa Nerd Font 12";
      };
    };
  };
}
