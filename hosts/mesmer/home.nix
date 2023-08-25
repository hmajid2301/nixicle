{
  inputs,
  lib,
  pkgs,
  config,
  outputs,
  ...
}: {
  imports =
    [
      inputs.nix-colors.homeManagerModule
      inputs.impermanence.nixosModules.home-manager.impermanence
      inputs.nixvim.homeManagerModules.nixvim
      inputs.nur.hmModules.nur

      ../../home-manager/desktops/hyprland
      ../../home-manager/desktops/gtk.nix
      ../../home-manager/fonts.nix

      ../../home-manager/shells/fish.nix
      ../../home-manager/terminals/alacritty.nix
      ../../home-manager/terminals/foot.nix

      ../../home-manager/browsers/firefox.nix
      ../../home-manager/apps/kdeconnect.nix
      ../../home-manager/apps/photos.nix

      ../../home-manager/programs/cli
      ../../home-manager/programs/cli/atuin
      ../../home-manager/programs/tuis
      ../../home-manager/editors/nvim
      ../../home-manager/programs/multiplexers/tmux.nix

      ../../home-manager/games
      ../../home-manager/security/sops.nix
      ../../home-manager/security/yubikey.nix
    ]
    ++ (builtins.attrValues outputs.homeManagerModules);

  nixpkgs = {
    overlays = builtins.attrValues outputs.overlays;
    config = {
      allowUnfree = true;
      allowUnfreePredicate = _: true;
    };
  };

  colorscheme = inputs.nix-colors.colorSchemes.catppuccin-frappe;
  wallpaper = "~/dotfiles/home-manager/wallpapers/rainbow-nix.jpg";
  host = "mesmer";

  nix = {
    package = lib.mkDefault pkgs.nix;
    settings = {
      experimental-features = ["nix-command" "flakes" "repl-flake"];
      warn-dirty = false;
    };
  };

  systemd.user.startServices = "sd-switch";

  programs = {
    home-manager.enable = true;
    git.enable = true;
  };

  home = {
    username = lib.mkDefault "haseeb";
    homeDirectory = lib.mkDefault "/home/${config.home.username}";
    stateVersion = lib.mkDefault "23.05";
    sessionPath = ["$HOME/.local/bin"];
    sessionVariables = {
      EDITOR = "nvim";
      TERMINAL = "alacritty";
      BROWSER = "firefox";
    };

    #persistence = {
    #  "/persist/home/haseeb" = {
    #    directories = [
    #      "Documents"
    #      "Downloads"
    #      "Pictures"
    #      "Videos"
    #      "Games"
    #      "projects"
    #      "dotfiles"
    #      "go"
    #      ".local"
    #      ".tmux"
    #      ".ssh"
    #      ".gnupg"
    #      ".config/gtk"
    #    ];
    #    allowOther = true;
    #  };
    #};
  };
}
