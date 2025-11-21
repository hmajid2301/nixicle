{
  config,
  lib,
  pkgs,
mkOpt ? null,
mkBoolOpt ? null,
enabled ? null,
disabled ? null,
  ...
}:
with lib;
let
  cfg = config.desktops.addons.caelestia;
in
{
  options.desktops.addons.caelestia = {
    enable = mkEnableOption "Enable Caelestia shell";

    enableSystemd = mkOption {
      type = types.bool;
      default = false;
      description = "Enable systemd service for auto-start";
    };

    systemdTarget = mkOption {
      type = types.str;
      default = "graphical-session.target";
      description = "Systemd target to bind to";
    };

    enableCli = mkOption {
      type = types.bool;
      default = true;
      description = "Enable caelestia-cli";
    };

    wallpaperDir = mkOption {
      type = types.str;
      default = "~/Pictures/Wallpapers";
      description = "Directory containing wallpapers";
    };

    settings = mkOption {
      type = types.attrs;
      default = { };
      description = "Additional settings to merge with the default configuration";
    };
  };

  config = mkIf cfg.enable {
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
