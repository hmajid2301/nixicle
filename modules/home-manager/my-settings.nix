{lib, ...}: let
  inherit (lib) types mkOption;
in {
  options.my.settings = {
    default = {
      shell = mkOption {
        type = types.nullOr (types.enum ["fish" "zsh"]);
        description = "The default shell to use";
        default = "fish";
      };

      terminal = mkOption {
        type = types.nullOr (types.enum ["alacritty" "foot" "wezterm"]);
        description = "The default terminal to use";
        default = "wezterm";
      };

      browser = mkOption {
        type = types.nullOr (types.enum ["firefox"]);
        description = "The default browser to use";
        default = "firefox";
      };

      editor = mkOption {
        type = types.nullOr (types.enum ["nvim" "code"]);
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

    fonts = {
      regular = mkOption {
        type = types.str;
        description = "The font for regular text";
        default = "Fira Sans";
      };

      monospace = mkOption {
        type = types.str;
        description = "The font for monospace text";
        default = "MonoLisa Nerd Font";
      };
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
