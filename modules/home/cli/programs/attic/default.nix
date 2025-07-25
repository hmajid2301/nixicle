{
  pkgs,
  config,
  lib,
  ...
}:
with lib;
with lib.nixicle;
let
  cfg = config.cli.programs.attic;
in
{
  options.cli.programs.attic = with types; {
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
        "attic-ci:U5Sey4mUxwBXM3iFapmP0/ogODXywKLRNgRPQpEXxbo="
        "main:VlacPrGj7LVuEavaWpEgun9eCNvB6DPqYMe3FraKGzw="
      ];
      netrc-file = config.sops.secrets."netrc".path;
    };
  };
}
