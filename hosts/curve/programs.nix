{ pkgs, lib, config, ... }: {
  imports = [
    ../../home-manager
    ../../home-manager/desktops/wms/sway.nix
    ../../home-manager/fonts.nix

    ../../home-manager/programs/android.nix
    ../../home-manager/programs/kdeconnect.nix

    ../../home-manager/programs
    ../../home-manager/programs/k8s.nix
    ../../home-manager/programs/kafka.nix
    ../../home-manager/programs/atuin

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

    home.packages = with pkgs; [
      podman-compose
      podman-tui
    ];
  };

}
