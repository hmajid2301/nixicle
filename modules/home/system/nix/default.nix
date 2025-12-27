{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  sharedNixConfig = import ../../../shared/nix-caches.nix;
in
{
  config = mkIf config.roles.non-nixos.enable {
    nix.settings = {
      auto-optimise-store = true;
    } // sharedNixConfig;
  };
}
