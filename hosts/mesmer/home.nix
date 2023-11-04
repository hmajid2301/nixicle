{ inputs
, pkgs
, lib
, config
, ...
}: {
  imports = [
    ../../home-manager
    ../../home-manager/desktops/wms/hyprland.nix

    ../../home-manager/games

    ../../home-manager/security/sops.nix
    ../../home-manager/security/yubikey.nix
  ];

  config = {
    modules = {
      browsers = {
        firefox.enable = true;
      };

      editors = {
        nvim.enable = true;
      };

      multiplexers = {
        tmux.enable = true;
      };

      shells = {
        fish.enable = true;
      };

      wms = {
        hyprland.enable = true;
        # TODO: conflict notifications
        notifications.swaync.enable = true;
        launchers.rofi.enable = true;
      };

      terminals = {
        foot.enable = true;
        wezterm.enable = true;
      };
    };

    my.settings = {
      wallpaper = "~/dotfiles/home-manager/wallpapers/nixppuccin.png";
      host = "mesmer";
      default = {
        shell = "${pkgs.fish}/bin/fish";
        terminal = "${pkgs.foot}/bin/foot";
        browser = "firefox";
        editor = "nvim";
      };
    };

    colorscheme = inputs.nix-colors.colorSchemes.catppuccin-mocha;

    home = {
      username = lib.mkDefault "haseeb";
      homeDirectory = lib.mkDefault "/home/${config.home.username}";
      stateVersion = lib.mkDefault "23.05";
    };
  };
}
