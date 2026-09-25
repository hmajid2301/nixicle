{ lib, inputs }:
let
  inherit (inputs) deploy-rs;

  extendedLib = lib.extend (
    self: _super: {
      nixicle = import ./. {
        inherit inputs;
        lib = self;
      };
    }
  );
in
rec {
  inherit extendedLib;

  secretsFile = ../modules/secrets.yaml;

  authorizedKeys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKuM4bCeJq0XQ1vd/iNK650Bu3wPVKQTSB0k2gsMKhdE hello@haseebmajid.dev"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINP5gqbEEj+pykK58djSI1vtMtFiaYcygqhHd3mzPbSt hello@haseebmajid.dev"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDwAamg3cSHP+91grc7qmrwNoPpbxD/IMi8MhqpptuM2 hello@haseebmajid.dev"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBZsm7CzZ50x8eaUrXaMmNRE2J9qK9E9X9vFHuv04E1V hello@haseebmajid.dev"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICLrECFz5PQ5D2+QXomsLK9HcZhHzcBUIDGkiI94c6Ux hello@haseebmajid.dev"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDuNpCUillp0oM7vFWpEf+EARQusfdOH2Sy1RlSDdDxr hello@haseebmajid.dev"
  ];

  nixicleOverlay = final: _prev: {
    nixicle = importPackages final ../packages;
  };

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

  domains = {
    root = "haseebmajid.dev";
    homelab = "homelab.haseebmajid.dev";
    sso = "id.haseebmajid.dev";
  };

  adminEmail = "hello@haseebmajid.dev";

  mkTraefikService =
    {
      name,
      port,
      subdomain ? name,
      domain ? domains.homelab,
      entryPoints ? [ "websecure" ],
      certResolver ? "letsencrypt",
      auth ? false,
      middlewares ? [ ],
      extraRouterConfig ? { },
      extraServiceConfig ? { },
    }:
    let
      allMiddlewares = (lib.optional auth "tinyauth") ++ middlewares;
    in
    {
      routers.${name} = lib.mkMerge [
        {
          inherit entryPoints;
          rule = lib.mkDefault "Host(`${subdomain}.${domain}`)";
          service = name;
          tls.certResolver = certResolver;
          middlewares = lib.mkDefault allMiddlewares;
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

  # Convenience wrapper kept for existing callers; equivalent to
  # mkTraefikService with auth = true (prepends the tinyauth middleware).
  mkAuthenticatedTraefikService = args: mkTraefikService (args // { auth = true; });
}
