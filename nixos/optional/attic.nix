{ config, pkgs, inputs, ... }: {
  imports = [ inputs.attic.nixosModules.atticd ];

  environment.systemPackages = with pkgs; [
    attic
  ];

  sops.secrets.attic_env = {
    sopsFile = ../secrets.yaml;
  };

  services.atticd = {
    enable = true;
    credentialsFile = config.sops.secrets.attic_env.path;
    settings = {
      storage = {
        type = "s3";
        region = "us-west-004";
        bucket = "majiy00-nix-cache";
        endpoint = "https://s3.us-west-004.backblazeb2.com";
      };

      listen = "127.0.0.1:8083";
      database.url = "postgresql:///atticd?host=/run/postgresql";
      require-proof-of-possession = false;
      garbage-collection = {
        interval = "3 days";
        default-retention-period = "1 month";
      };
      chunking = {
        nar-size-threshold = 64 * 1024; # 64 KiB
        min-size = 16 * 1024; # 16 KiB
        avg-size = 64 * 1024; # 64 KiB
        max-size = 256 * 1024; # 256 KiB
      };
    };
  };

  services.postgresql = {
    enable = true;
    ensureUsers = [{
      name = "atticd";
      ensurePermissions = {
        "DATABASE atticd" = "ALL PRIVILEGES";
      };
    }];
    ensureDatabases = [ "atticd" ];
  };
}
