{
  config,
  lib,
  inputs,
  ...
}:
with lib;
with lib.nixicle;
let
  cfg = config.system.nix;
in
{
  options.system.nix = with types; {
    enable = mkBoolOpt false "Whether or not to manage nix configuration";
  };

  config = mkIf cfg.enable {
    nix = {
      settings = {
        trusted-users = [
          "@wheel"
          "root"
        ];
        auto-optimise-store = lib.mkDefault true;
        use-xdg-base-directories = true;
        experimental-features = [
          "nix-command"
          "flakes"
        ];
        warn-dirty = false;
        system-features = [
          "kvm"
          "big-parallel"
          "nixos-test"
        ];
        flake-registry = "";

        substituters = [
          "https://cache.nixos.org"
          "https://nix-community.cachix.org"
          "https://numtide.cachix.org"
        ];
        trusted-public-keys = [
          "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
          "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
          "numtide.cachix.org-1:2ps1kLBUWjxIneOy1Ik6cQjb41X0iXVXeHigGmycPPE="
        ];
      };

      registry.nixpkgs.flake = inputs.nixpkgs;

      gc = {
        automatic = lib.mkDefault true;
        dates = lib.mkDefault "weekly";
        options = lib.mkDefault "--delete-older-than 7d";
      };

      optimise = {
        automatic = lib.mkDefault true;
        dates = lib.mkDefault [ "weekly" ];
      };
    };
  };
}
