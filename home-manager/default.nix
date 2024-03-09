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
      inputs.impermanence.nixosModules.home-manager.impermanence

      ./programs
      ./scripts.nix

      ./browsers/firefox.nix

      ./editors/nvim

      ./multiplexers/tmux.nix
      ./multiplexers/zellij

      ./desktops/hyprland

      ./shells/fish.nix
      ./shells/nushell.nix
      ./shells/zsh.nix

      ./terminals/alacritty.nix
      ./terminals/foot.nix
      ./terminals/wezterm

      ./security/sops.nix
    ]
    ++ builtins.attrValues outputs.homeManagerModules;

  systemd.user.startServices = "sd-switch";

  programs = {
    home-manager.enable = true;
  };

  home.sessionVariables.EDITOR = config.my.settings.default.editor;

  nixpkgs = {
    overlays =
      builtins.attrValues outputs.overlays
      ++ [
        inputs.nixgl.overlay
      ];

    config = {
      allowUnfree = true;
      allowUnfreePredicate = _: true;
    };
  };

  home.packages = [pkgs.nixgl.nixGLIntel];

  nix = {
    package = lib.mkDefault pkgs.nix;
    settings = {
      trusted-substituters = [
        "https://cache.nixos.org"
        "https://nix-community.cachix.org"
      ];

      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      ];

      experimental-features = ["nix-command" "flakes" "repl-flake"];
      warn-dirty = false;
      use-xdg-base-directories = true;
      netrc-file = "$HOME/.config/nix/netrc";
    };
  };

  news = {
    display = "silent";
    json = lib.mkForce {};
    entries = lib.mkForce [];
  };
}
