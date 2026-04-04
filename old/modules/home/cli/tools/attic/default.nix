{
  pkgs,
  config,
  lib,
  ...
}:
with lib;
with lib.nixicle;

let
  cfg = config.cli.tools.attic;
in
{
  options.cli.tools.attic = with types; {
    enable = mkBoolOpt false "Whether or not to enable attic";
  };

  config = mkIf cfg.enable {
    sops.secrets.netrc = {
      sopsFile = ../../../secrets.yaml;
    };

    home.packages = with pkgs; [
      attic-client
    ];

    nix.settings = {
      trusted-substituters = [
        "https://staging.attic.rs/attic-ci"
        "https://attic.homelab.haseebmajid.dev/main"
      ];
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "attic-ci:U5Sey4mUxwBXM3iFapmP0/ogODXywKLRNgRPQpEXxbo="
        "main:VlacPrGj7LVuEavaWpEgun9eCNvB6DPqYMe3FraKGzw="
      ];
      netrc-file = config.sops.secrets."netrc".path;
    };
  };
}
