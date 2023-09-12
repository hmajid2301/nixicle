{ inputs
, lib
, pkgs
, config
, ...
}:
{
  imports = [
    inputs.nix-colors.homeManagerModule
    inputs.nixvim.homeManagerModules.nixvim
    inputs.nur.hmModules.nur

    ./programs.nix
  ];

  my.settings = {
    wallpaper = "../../home-manager/wallpapers/rainbow-nix.jpg";
    host = "curve";
    defaultShell = "fish";
    defaultTerminal = "foot";
    defaultBrowser = "firefox";
    defaultEditor = "nvim";
  };

  colorscheme = inputs.nix-colors.colorSchemes.catppuccin-frappe;

  home = {
    username = lib.mkDefault "haseebmajid";
    homeDirectory = lib.mkDefault "/home/${config.home.username}";
    stateVersion = lib.mkDefault "23.05";
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
}
