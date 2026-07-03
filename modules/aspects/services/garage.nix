{ ... }:
{
  den.aspects.garage = {
    includes = [ ];
    persist.directories = [ "/var/lib/private/garage" ];
    nixos =
      {
        pkgs,
        config,
        ...
      }:
      {
        config = {
          sops.secrets.garage_rpc_secret = {
                        key = "garage_rpc_secret";
            mode = "0400";
          };

          services.garage = {
            enable = true;
            package = pkgs.garage;
            environmentFile = config.sops.secrets.garage_rpc_secret.path;
            settings = {
              metadata_dir = "/var/lib/garage/meta";
              data_dir = "/var/lib/garage/data";
              db_engine = "lmdb";
              replication_factor = 1;
              rpc_bind_addr = "127.0.0.1:3901";
              rpc_public_addr = "127.0.0.1:3901";
              s3_api = {
                s3_region = "garage";
                api_bind_addr = "127.0.0.1:3900";
                root_domain = ".s3.garage.localhost";
              };
              admin = {
                api_bind_addr = "127.0.0.1:3903";
              };
            };
          };
        };
      };
  };
}
