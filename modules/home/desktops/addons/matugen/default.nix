{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
with lib.nixicle;
let
  cfg = config.desktops.addons.matugen;
in
{
  options.desktops.addons.matugen = with types; {
    enable = mkBoolOpt false "Enable matugen Material You color generation";

    variant = mkOption {
      type = enum [ "light" "dark" "amoled" ];
      default = "dark";
      description = "Color scheme variant (light, dark, or amoled)";
    };

    wallpaperPath = mkOption {
      type = nullOr str;
      default = null;
      description = "Path to wallpaper for color extraction. If null, uses current wallpaper.";
    };

    templates = mkOption {
      type = attrsOf str;
      default = { };
      description = ''
        Custom template definitions for color export.
        Keys are template names, values are template paths.
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
    ];

    xdg.configFile."matugen/config.toml" = mkIf (cfg.templates != { }) {
      text = ''
        [config]
        variant = "${cfg.variant}"

        ${optionalString (cfg.wallpaperPath != null) ''
        [source]
        type = "image"
        path = "${cfg.wallpaperPath}"
        ''}

        ${concatStringsSep "\n" (mapAttrsToList
          (name: path: ''
            [templates.${name}]
            input_path = "${path}"
          '')
          cfg.templates
        )}
      '';
    };
  };
}
