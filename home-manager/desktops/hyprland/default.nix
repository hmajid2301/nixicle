{ inputs
, config
, pkgs
, ...
}: {
  imports = [
    inputs.hyprland.homeManagerModules.default
    ../wayland
  ];

  home.packages = [
    inputs.hypr-contrib.packages.${pkgs.system}.grimblast
    inputs.hyprland.packages.${pkgs.system}.xdg-desktop-portal-hyprland
  ];

  wayland.windowManager.hyprland = {
    enable = true;
    # TODO: rewrite using settings https://mipmip.github.io/home-manager-option-search/?query=hyprland.
    extraConfig = import ./config.nix {
      inherit (config) home colorscheme wallpaper;
    };
  };
}
