{ lib, ... }:
let
  inherit (lib) types mkOption;
in
{
  options.my.settings = {
    defaultShell = mkOption {
      type = types.nullOr (types.enum [ "fish" "zsh" ]);
      description = "The default shell to use";
      default = "fish";
    };

    defaultTerminal = mkOption {
      type = types.nullOr (types.enum [ "alacritty" "foot" ]);
      description = "The default terminal to use";
      default = "foot";
    };

    defaultBrowser = mkOption {
      type = types.nullOr (types.enum [ "firefox" ]);
      description = "The default browser to use";
      default = "firefox";
    };

    defaultEditor = mkOption {
      type = types.nullOr (types.enum [ "nvim" "code" ]);
      description = "The default editor to use";
      default = "nvim";
    };

    wallpaper = mkOption {
      type = types.str;
      default = "";
      description = ''
        Wallpaper path
      '';
    };

    host = mkOption {
      type = types.str;
      default = "";
      description = ''
        Name of the host
      '';
    };
  };
}
