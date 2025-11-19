{delib, ...}:
delib.rice {
  name = "catppuccin";

  myconfig = {
    rices.catppuccin = {
      colorscheme = "catppuccin-mocha";
    };
  };

  nixos = {...}: {
    # Catppuccin theming for NixOS
  };

  home = {...}: {
    # Catppuccin theming for home-manager
  };
}
