{ inputs
, lib
, config
, ...
}: {
  imports = [
    ./programs.nix
  ];

  my.settings = {
    host = "iso";
    default = {
      shell = "fish";
      terminal = "foot";
      browser = "firefox";
      editor = "nvim";
    };
  };

  colorscheme = inputs.nix-colors.colorSchemes.catppuccin-mocha;

  home = {
    username = lib.mkDefault "nixos";
    homeDirectory = lib.mkDefault "/home/${config.home.username}";
    stateVersion = lib.mkDefault "23.05";
  };
}
