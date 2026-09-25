# System-level attic binary cache substitution for server hosts (vps, nas, etc).
# Sets the private `main` attic cache as the first substituter and wires the
# `netrc` sops secret so the nix daemon authenticates (the cache is private).
# Desktop-class hosts get the same config inline via the `common` profile; this
# aspect is for server hosts that don't include `common`.
_: {
  den.aspects.attic-cache = {
    nixos =
      { config, lib, ... }:
      {
        # Same netrc secret the common profile + HM attic client use: a 10y
        # pull+push JWT for `machine attic.${config.nixicle.domains.root}`.
        sops.secrets.netrc.sopsFile = lib.nixicle.secretsFile;

        nix.settings = {
          substituters = [
            "https://attic.${config.nixicle.domains.root}/main"
            "https://cache.nixos.org"
            "https://nix-community.cachix.org"
            "https://numtide.cachix.org"
          ];
          trusted-public-keys = [
            "main:+A4BR+E8F8FNe1YR6Uq8qGO5dVj8y1kaalW3kQ0WgXo="
            "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
            "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
            "numtide.cachix.org-1:2ps1kLBUWjxIneOy1Ik6cQjb41X0iXVXeHigGmycPPE="
          ];
          # Authenticate to the private attic cache; attic accepts the JWT as
          # a Basic-auth password (login may be empty).
          netrc-file = config.sops.secrets."netrc".path;
          fallback = true;
        };
      };
  };
}
