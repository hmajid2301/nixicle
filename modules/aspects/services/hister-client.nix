_: {
  den.aspects.histerClient = {
    homeManager =
      {
        pkgs,
        config,
        lib,
        ...
      }:
      {
        sops.secrets.hister_token = {
          sopsFile = lib.nixicle.secretsFile;
        };

        sops.templates."hister-config.yml" = {
          content = ''
            server:
              base_url: https://hister.${lib.nixicle.domains.root}
            app:
              access_token: ${config.sops.placeholder.hister_token}
          '';
          path = "${config.xdg.configHome}/hister/config.yml";
          mode = "0600";
        };

        home.packages = [ pkgs.hister ];
      };
  };
}
