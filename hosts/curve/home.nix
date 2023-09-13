{ inputs
, lib
, config
, ...
}: {
  imports = [
    ./programs.nix
  ];

  my.settings = {
    wallpaper = "../../home-manager/wallpapers/rainbow-nix.jpg";
    host = "curve";
    default = {
      shell = "fish";
      terminal = "foot";
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
}
