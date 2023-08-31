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

      ../../home-manager/desktops/gnome
      #../../home-manager/desktops/gtk.nix
      ../../home-manager/fonts.nix

      ../../home-manager/shells/fish.nix
      ../../home-manager/terminals/alacritty.nix
      ../../home-manager/terminals/foot.nix

      ../../home-manager/programs/android.nix
      ../../home-manager/programs/kdeconnect.nix
      ../../home-manager/browsers/firefox.nix

      ../../home-manager/editors/nvim
      ../../home-manager/multiplexers/tmux.nix

      ../../home-manager/programs
      ../../home-manager/programs/k8s.nix
      ../../home-manager/programs/kafka.nix
      ../../home-manager/programs/atuin

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

  targets.genericLinux.enable = true;
  xdg.mime.enable = true;
  xdg.systemDirs.data = ["${config.home.homeDirectory}/.nix-profile/share/applications"];

  programs.git.userEmail = lib.mkForce "haseeb.majid@imaginecurve.com";
  programs.git.extraConfig."url \"git@git.curve.tools:\"" = {insteadOf = "https://git.curve.tools/";};
  programs.git.extraConfig."url \"git@gitlab.com:imaginecurve/\"" = {insteadOf = "https://gitlab.com/imaginecurve";};
}
