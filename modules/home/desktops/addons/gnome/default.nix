{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.desktops.addons.gnome;
in {
  options.desktops.addons.gnome = {
    enable = mkEnableOption "enable gnome extras to work with home-manager";
  };

  config = mkIf cfg.enable {
    xdg = {
      mime.enable = true;
      systemDirs.data = [
        "${config.home.homeDirectory}/.nix-profile/share/applications"
        "${config.home.homeDirectory}/state/nix/profile/share/applications"
      ];
    };
    targets.genericLinux.enable = true;
  };
}
