{ den, ... }:
{
  den.aspects.attic = {
    homeManager = { pkgs, config, ... }: {
      sops.secrets.netrc = {
        sopsFile = ../secrets.yaml;
      };

      home.packages = [ pkgs.attic-client ];

      nix.settings.netrc-file = config.sops.secrets."netrc".path;
    };
  };
}
