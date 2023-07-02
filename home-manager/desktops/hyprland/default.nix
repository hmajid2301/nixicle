{ inputs, config, pkgs, ... }: {
  imports = [
    inputs.hyprland.homeManagerModules.default
    ../wayland
  ];

  home.packages = with pkgs; [
    dconf
    inputs.hypr-contrib.packages.${pkgs.system}.grimblast
    inputs.hyprland.packages.${pkgs.system}.xdg-desktop-portal-hyprland
  ];

  wayland.windowManager.hyprland = {
    enable = true;
    extraConfig = (import ./config.nix {
      inherit (config) home colorscheme wallpaper;
    });
  };
}
