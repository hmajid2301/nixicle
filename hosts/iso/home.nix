{ inputs
, lib
, config
, ...
}: {
  imports = [
    ../../home-manager
    ../../home-manager/programs
  ];

  config = {
    modules = {
      editors = {
        nvim.enable = true;
      };

      shells = {
        fish.enable = true;
      };

      terminals = {
        foot.enable = true;
      };
    };

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
  };
}
