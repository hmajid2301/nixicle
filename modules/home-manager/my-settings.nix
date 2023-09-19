{ lib, pkgs, ... }:
let
  inherit (lib) types mkOption;
in
{
  options.my.settings = {

    default = {
      shell = mkOption {
        type = types.nullOr (types.enum [ "${pkgs.fish}/bin/fish" "${pkgs.zsh}/bin/zsh" ]);
        description = "The default shell to use";
        default = "${pkgs.fish}/bin/fish";
      };

      terminal = mkOption {
        type = types.nullOr (types.enum [ "alacritty" "${pkgs.foot}/bin/foot" ]);
        description = "The default terminal to use";
        default = "${pkgs.foot}/bin/foot";
      };

      browser = mkOption {
        type = types.nullOr (types.enum [ "firefox" ]);
        description = "The default browser to use";
        default = "firefox";
      };

      editor = mkOption {
        type = types.nullOr (types.enum [ "nvim" "code" ]);
        description = "The default editor to use";
        default = "nvim";
      };
    };

    impermanenceEnabled = mkOption {
      type = types.bool;
      description = "Whether to enable impermanence to delete home directory on reboot";
      default = false;
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
