{ den, ... }:
{
  den.aspects.blog-previews = {
    includes = [
      den.aspects.gitlab-runner
      den.aspects.traefik
    ];

    nixos =
      {
        config,
        lib,
        pkgs,
        ...
      }:
      let
        root = "/srv/blog-previews";
        port = 8787;
        maxAgeDays = 14;
      in
      {
        systemd = {
          tmpfiles.rules = [ "d ${root} 0755 root root -" ];

          services.blog-previews-prune = {
            description = "Delete blog previews older than ${toString maxAgeDays} days";
            serviceConfig.Type = "oneshot";
            script = ''
              ${pkgs.findutils}/bin/find ${root} -mindepth 1 -maxdepth 1 -type d \
                -mtime +${toString maxAgeDays} -print -exec ${pkgs.coreutils}/bin/rm -rf {} +
            '';
          };

          timers.blog-previews-prune = {
            wantedBy = [ "timers.target" ];
            timerConfig = {
              OnCalendar = "daily";
              Persistent = true;
            };
          };
        };

        services = {
          gitlab-runner.services.default.dockerVolumes = [ "${root}:/previews:rw" ];

          static-web-server = {
            enable = true;
            listen = "127.0.0.1:${toString port}";
            inherit root;
            configuration.general = {
              directory-listing = false;
              redirect-trailing-slash = true;
              compression = true;
            };
            configuration.advanced.headers = [
              {
                source = "**";
                headers.X-Robots-Tag = "noindex, nofollow";
              }
            ];
          };

          traefik.dynamicConfigOptions.http = lib.nixicle.mkTraefikService {
            name = "blog-previews";
            subdomain = "preview";
            domain = config.nixicle.domains.root;
            inherit port;
          };
        };
      };
  };
}
