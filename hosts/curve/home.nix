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
      inputs.nixvim.homeManagerModules.nixvim
      inputs.nur.hmModules.nur

      ../../home-manager/desktops/hyprland
      #../../home-manager/desktops/gtk.nix
      ../../home-manager/fonts.nix

      ../../home-manager/shells/fish.nix
      ../../home-manager/terminals/alacritty.nix
      ../../home-manager/terminals/foot.nix

      ../../home-manager/programs/cli
      ../../home-manager/programs/cli/k8s.nix
      ../../home-manager/programs/cli/kafka.nix
      ../../home-manager/programs/pritunl.nix
      ../../home-manager/programs/tuis
      ../../home-manager/programs/android.nix
      ../../home-manager/editors/nvim
      ../../home-manager/programs/multiplexers/tmux.nix
      ../../home-manager/browsers/firefox.nix

      ../../home-manager/atuin

      ../../home-manager/security/sops.nix
      ../../home-manager/security/yubikey.nix
      ../../home-manager/programs/kdeconnect.nix
      ../../home-manager/packages/other.nix
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
  host = "curve";

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
    username = lib.mkDefault "haseebmajid";
    homeDirectory = lib.mkDefault "/home/${config.home.username}";
    stateVersion = lib.mkDefault "23.05";
    sessionPath = ["$HOME/.local/bin"];
    sessionVariables = {
      BROWSER = "chrome";
      EDITOR = "nvim";
      TERMINAL = "foot";
    };
  };
}