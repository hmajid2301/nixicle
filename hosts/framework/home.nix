{ inputs, lib, pkgs, config, outputs, ... }:
let
  inherit (inputs.nix-colors) colorSchemes;
in
{
  imports = [
    inputs.nix-colors.homeManagerModule
    inputs.impermanence.nixosModules.home-manager.impermanence
    inputs.nur.hmModules.nur
    ../../home-manager/editors/nvim
    ../../home-manager/packages/coding.nix
    ../../home-manager/packages/other.nix
    ../../home-manager/programs/cli.nix
    ../../home-manager/browsers/firefox.nix
    #../../home-manager/security/yubikey.nix
    ../../home-manager/terminals/alacritty.nix
    ../../home-manager/shells/fish.nix
    ../../home-manager/desktops/hyprland
    ../../home-manager/gtk.nix
    ../../home-manager/fonts.nix
    ../../home-manager/games
  ] ++ (builtins.attrValues outputs.homeManagerModules);

  nixpkgs = {
    overlays = builtins.attrValues outputs.overlays;
    config = {
      allowUnfree = true;
      allowUnfreePredicate = (_: true);
    };
  };

  colorscheme = inputs.nix-colors.colorSchemes.catppuccin-frappe;

  nix = {
    package = lib.mkDefault pkgs.nix;
    settings = {
      experimental-features = [ "nix-command" "flakes" "repl-flake" ];
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
    sessionPath = [ "$HOME/.local/bin" ];
    sessionVariables = {
      EDITOR = "nvim";
      GTK_THEME = "catppuccin";
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

