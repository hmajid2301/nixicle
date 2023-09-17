{
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
  };
}
