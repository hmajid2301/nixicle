{ inputs
, pkgs
, lib
, config
, ...
}: {
  imports = [
    ../../home-manager
    ../../home-manager/desktops/wms/hyprland.nix

    ../../home-manager/programs/android.nix
    ../../home-manager/programs/atuin.nix
    ../../home-manager/programs/kdeconnect.nix

    ../../home-manager/games

    ../../home-manager/programs/k8s.nix

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

      terminals = {
        alacritty.enable = true;
        foot.enable = true;
      };
    };

    my.settings = {
      wallpaper = "../../home-manager/wallpapers/rainbow-nix.jpg";
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

      #persistence = {
      #  "/persist/home/haseeb" = {
      #    directories = [
      #      "Documents"
      #      "Downloads"
      #      "Pictures"
      #      "Videos"
      #      "Games"
      #      "projects"
      #      "dotfiles"
      #      "go"
      #      ".local"
      #      ".tmux"
      #      ".ssh"
      #      ".gnupg"
      #      ".config/gtk"
      #    ];
      #    allowOther = true;
      #  };
      #};
    };
  };
}
