{
  config,
  lib,
  pkgs,
  mkBoolOpt ? null,
  ...
}:
with lib;

let
  cfg = config.system.home-nix;
in
{
  options.system.home-nix = with types; {
    enable = mkBoolOpt true "Whether to manage nix configuration in home-manager";
  };

  config = mkIf cfg.enable {
    # Set nix package once for all home-manager configs
    nix.package = lib.mkDefault pkgs.nix;

    # User-level nix cache configuration for standalone home-manager
    nix.settings = {
      extra-substituters = [
        "https://nix-community.cachix.org"
        "https://numtide.cachix.org"
        "https://nvim-treesitter-main.cachix.org"
        "https://hyprland.cachix.org"
        "https://niri.cachix.org"
      ];
      extra-trusted-public-keys = [
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "numtide.cachix.org-1:2ps1kLBUWjxIneOy1Ik6cQjb41X0iXVXeHigGmycPPE="
        "nvim-treesitter-main.cachix.org-1:cbwE6blfW5+BkXXyeAXoVSu1gliqPLHo2m98E4hWfZQ="
        "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
        "niri.cachix.org-1:Wv0OmO7PsuocRKzfDoJ3mulSl7Z6oezYhGhR+3W2964="
      ];
    };
  };
}
