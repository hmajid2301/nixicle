{config, ...}: {
  imports = [
    ../wayland
  ];

  wayland.windowManager.sway = {
    enable = true;
    # Assume we are using swayfx
    package = null;
    # TODO use config options: https://github.com/nix-community/home-manager/blob/master/modules/services/window-managers/i3-sway/sway.nix
    config = null;
    extraConfig = import ./config.nix {
      inherit (config) home colorscheme wallpaper;
    };
  };
}
