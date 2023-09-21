{ pkgs
, inputs
, lib
, config
, ...
}: {
  imports = [
    ../../home-manager
    ../../home-manager/desktops/wms/sway.nix
    ../../home-manager/fonts.nix

    ../../home-manager/programs/atuin.nix
    ../../home-manager/programs/android.nix
    ../../home-manager/programs/kdeconnect.nix

    ../../home-manager/programs
    ../../home-manager/programs/k8s.nix
    ../../home-manager/programs/kafka.nix

    ../../home-manager/security/sops.nix
    ../../home-manager/security/yubikey.nix
  ];

  config = {
    my.settings = {
      wallpaper = "~/dotfiles/home-manager/wallpapers/rainbow-nix.jpg";
      host = "curve";
      default = {
        shell = "${pkgs.fish}/bin/fish";
        terminal = "${pkgs.foot}/bin/foot";
        browser = "firefox";
        editor = "nvim";
      };
    };

    colorscheme = inputs.nix-colors.colorSchemes.catppuccin-mocha;

    home = {
      username = lib.mkDefault "haseebmajid";
      homeDirectory = lib.mkDefault "/home/${config.home.username}";
      stateVersion = lib.mkDefault "23.05";
    };
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
        foot.enable = true;
      };
    };

    # To show nix installed apps in Gnome
    targets.genericLinux.enable = true;
    xdg.mime.enable = true;
    xdg.systemDirs.data = [ "${config.home.homeDirectory}/.nix-profile/share/applications" ];

    # Work Laptop different email
    programs.git.userEmail = lib.mkForce "haseeb.majid@imaginecurve.com";
    programs.git.extraConfig."url \"git@git.curve.tools:\"" = { insteadOf = "https://git.curve.tools/"; };
    programs.git.extraConfig."url \"git@gitlab.com:imaginecurve/\"" = { insteadOf = "https://gitlab.com/imaginecurve"; };

    # sway (swayfx) is installed via manually building binaries
    wayland.windowManager.sway.package = lib.mkForce null;
    gtk.enable = lib.mkForce false;

    home.packages = with pkgs; [
      podman-compose
      podman-tui
    ];
  };
}
