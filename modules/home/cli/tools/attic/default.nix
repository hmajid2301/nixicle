{delib, ...}:
delib.module {
  name = "cli-tools-attic";

  options.cli.tools.attic = with delib; {
    enable = boolOption false;
  };

  home.always = {config, lib, pkgs, ...}:
  with lib;
  with lib.nixicle;
  let
    cfg = config.cli.tools.attic;
  in
  mkIf cfg.enable {
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
