{
  inputs,
  lib,
  config,
  ...
}: {
  imports = [
    ../../home-manager
  ];

  config = {
    home.file.".config/autostart/foot.desktop".text = ''
      [Desktop Entry]
      Type=Application
      Exec=foot -m fish -c 'nix_installer' 2>&1
      Hidden=false
      NoDisplay=false
      X-GNOME-Autostart-enabled=true
      Name[en_NG]=Terminal
      Name=Terminal
      Comment[en_NG]=Start Terminal On Startup
      Comment=Start Terminal On Startup
    '';

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
      fonts.monospace = "FiraCode Nerd Font Mono";
    };

    colorscheme = inputs.nix-colors.colorSchemes.catppuccin-mocha;

    home = {
      username = lib.mkDefault "nixos";
      homeDirectory = lib.mkDefault "/home/${config.home.username}";
      stateVersion = lib.mkDefault "23.05";
    };
  };
}
