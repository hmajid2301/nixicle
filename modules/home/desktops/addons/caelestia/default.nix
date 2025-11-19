{delib, ...}:
delib.module {
  name = "desktops-addons-caelestia";

  options.desktops.addons.caelestia = with delib; {
    enable = boolOption false;
    enableSystemd = boolOption false;
    systemdTarget = strOption "graphical-session.target";
    enableCli = boolOption true;
    wallpaperDir = strOption "~/Pictures/Wallpapers";
    settings = attrsOption {};
  };

  home.always = {config, lib, pkgs, ...}:
  with lib;
  let
    cfg = config.desktops.addons.caelestia;
  in
  mkIf cfg.enable {
    # Copy the shell.json configuration to the appropriate location
    xdg.configFile."caelestia/shell.json".text = let
      defaultConfig = builtins.fromJSON (builtins.readFile ./shell.json);
      # Merge user settings with defaults
      mergedConfig = recursiveUpdate defaultConfig (recursiveUpdate
        {
          paths.wallpaperDir = cfg.wallpaperDir;
        }
        cfg.settings
      );
    in
      builtins.toJSON mergedConfig;

    programs.caelestia = {
      enable = true;
      systemd = {
        enable = cfg.enableSystemd;
        target = cfg.systemdTarget;
        environment = [ ];
      };
      settings = cfg.settings;
      cli = {
        enable = cfg.enableCli;
        settings = {
          theme.enableGtk = true;
        };
      };
    };
  };
}
