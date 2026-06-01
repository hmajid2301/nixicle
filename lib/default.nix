{ lib, inputs }:
let
  inherit (inputs) deploy-rs;
in
rec {
  importPackages =
    pkgs: dir:
    let
      entries = builtins.readDir dir;
      processEntry =
        name: type:
        if type == "directory" && builtins.pathExists (dir + "/${name}/default.nix") then
          { ${name} = pkgs.callPackage (dir + "/${name}") { inherit inputs; }; }
        else
          { };
    in
    lib.foldl' (acc: entry: acc // entry) { } (lib.mapAttrsToList processEntry entries);

  mkDeploy =
    {
      self,
      overrides ? { },
    }:
    let
      hosts = self.nixosConfigurations or { };
      names = builtins.attrNames hosts;
      nodes = lib.foldl (
        result: name:
        let
          host = hosts.${name};
          user = host.config.user.name or null;
          inherit (host.pkgs.stdenv.hostPlatform) system;
        in
        result
        // {
          ${name} = (overrides.${name} or { }) // {
            hostname = overrides.${name}.hostname or "${name}";
            profiles = (overrides.${name}.profiles or { }) // {
              system =
                (overrides.${name}.profiles.system or { })
                // {
                  path = deploy-rs.lib.${system}.activate.nixos host;
                }
                // lib.optionalAttrs (user != null) {
                  user = "root";
                  sshUser = user;
                }
                // lib.optionalAttrs (host.config.security.nixicle.doas.enable or false) {
                  sudo = "doas -u";
                };
            };
          };
        }
      ) { } names;
    in
    {
      inherit nodes;
    };

  mkTraefikService =
    {
      name,
      port,
      subdomain ? name,
      domain ? "homelab.haseebmajid.dev",
      entryPoints ? [ "websecure" ],
      certResolver ? "letsencrypt",
      middlewares ? [ ],
      extraRouterConfig ? { },
      extraServiceConfig ? { },
    }:
    {
      routers.${name} = lib.mkMerge [
        {
          inherit entryPoints;
          rule = lib.mkDefault "Host(`${subdomain}.${domain}`)";
          service = name;
          tls.certResolver = certResolver;
          inherit middlewares;
        }
        extraRouterConfig
      ];
      services.${name} = lib.mkMerge [
        {
          loadBalancer.servers = lib.mkDefault [ { url = "http://localhost:${toString port}"; } ];
        }
        extraServiceConfig
      ];
    };

  mkAuthenticatedTraefikService =
    {
      name,
      port,
      subdomain ? name,
      domain ? "homelab.haseebmajid.dev",
      entryPoints ? [ "websecure" ],
      certResolver ? "letsencrypt",
      middlewares ? [ ],
      extraRouterConfig ? { },
      extraServiceConfig ? { },
    }:
    {
      routers.${name} = lib.mkMerge [
        {
          inherit entryPoints;
          rule = lib.mkDefault "Host(`${subdomain}.${domain}`)";
          service = name;
          tls.certResolver = certResolver;
          middlewares = middlewares ++ [ "authentik" ];
        }
        extraRouterConfig
      ];
      services.${name} = lib.mkMerge [
        {
          loadBalancer.servers = lib.mkDefault [ { url = "http://localhost:${toString port}"; } ];
        }
        extraServiceConfig
      ];
    };
}
