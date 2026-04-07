{ den, inputs, lib, ... }:
let
  tunnelId = "ecef5dbb-834e-43ed-84c6-355a2ac53e59";
in
{
  flake-file.inputs.tangled = {
    url = "git+https://tangled.sh/@tangled.sh/core";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  den.aspects.tangled = {
    includes = [
      den.aspects.nixery
      den.aspects.openbao
    
      (import ./_persist-forwarder.nix { inherit den lib; })
    ];
    persist.directories = [
          { directory = "/home/git"; user = "git"; group = "git"; mode = "0750"; }
          { directory = "/var/lib/spindle"; user = "root"; group = "root"; mode = "0755"; }
        ];

    nixos = { config, pkgs, lib, ... }: {
      imports = [
        inputs.tangled.nixosModules.knot
        inputs.tangled.nixosModules.spindle
      ];
      services = {
        tangled = {
          knot = {
            enable = true;
            package = inputs.tangled.packages.${pkgs.stdenv.hostPlatform.system}.knot;
            server = {
              owner = "did:plc:reouqbpvl2kbkhvok2pwhlzg";
              hostname = "tangled.haseebmajid.dev";
            };
          };
          spindle = {
            enable = true;
            package = inputs.tangled.packages.${pkgs.stdenv.hostPlatform.system}.spindle;
            server = {
              owner = "did:plc:reouqbpvl2kbkhvok2pwhlzg";
              hostname = "spindle.haseebmajid.dev";
              secrets = {
                provider = "openbao";
                openbao = {
                  proxyAddr = "http://127.0.0.1:8202";
                  mount = "spindle";
                };
              };
            };
          };
        };
        cloudflared.tunnels.${tunnelId}.ingress = {
          "tangled.haseebmajid.dev".service = "http://localhost:5555";
          "spindle.haseebmajid.dev".service = "http://localhost:6555";
          "git.haseebmajid.dev".service = "ssh://localhost:22";
        };
      };

    };
  };
}
