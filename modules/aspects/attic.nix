{ den, ... }:
{
  den.aspects.attic = {
    homeManager = { pkgs, config, ... }: {
      sops.secrets.netrc = {
        sopsFile = ../../old/modules/home/secrets.yaml;
      };

      home.packages = [ pkgs.attic-client ];

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
  };
}
