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
  sharedNixConfig = import ../../../shared/nix-caches.nix;
in
{
  options.system.nix = with types; {
    enable = mkBoolOpt false "Whether or not to manage nix configuration";
  };

  config = mkIf cfg.enable {
    nix = {
      # Disable NIX_PATH and channels since we're using flakes
      channel.enable = false;
      nixPath = [ "nixpkgs=flake:nixpkgs" ];

      settings = {
        trusted-users = [
          "@wheel"
          "root"
        ];
        auto-optimise-store = lib.mkDefault true;
        system-features = [
          "kvm"
          "big-parallel"
          "nixos-test"
        ];
        flake-registry = "";
        require-sigs = true;
        fallback = true;
      } // sharedNixConfig;

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
