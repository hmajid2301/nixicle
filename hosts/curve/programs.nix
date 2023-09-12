{
  imports = [
    ../../home-manager
    ../../home-manager/desktops/wms/sway.nix
    #../../home-manager/desktops/gtk.nix
    ../../home-manager/fonts.nix

    ../../home-manager/terminals/foot.nix

    ../../home-manager/programs/android.nix
    ../../home-manager/programs/kdeconnect.nix
    ../../home-manager/browsers/firefox.nix

    ../../home-manager/editors/nvim
    ../../home-manager/multiplexers/tmux.nix

    ../../home-manager/programs
    ../../home-manager/programs/k8s.nix
    ../../home-manager/programs/kafka.nix
    ../../home-manager/programs/atuin

    ../../home-manager/security/sops.nix
    ../../home-manager/security/yubikey.nix
  ];

  config = {
    modules = {
      shells = {
        fish.enable = true;
      };

      terminals = {
        foot.enable = true;
      };
    };
  };
}
