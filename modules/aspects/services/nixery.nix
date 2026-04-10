{
  den,
  inputs,
  lib,
  ...
}:
let
  port = 8091;
  channel = "nixos-unstable";
in
{
  flake-file.inputs.nixery = {
    url = "github:tazjin/nixery";
    flake = false;
  };
  den.aspects.nixery = {
    includes = [ (import ./_persist-forwarder.nix { inherit den lib; }) ];
    persist.directories = [ "/var/lib/private/nixery" ];
    nixos =
      {
        pkgs,
        ...
      }:
      {
        systemd.services.nixery = {
          description = "Nixery Container Registry";
          wantedBy = [ "multi-user.target" ];
          after = [ "network.target" ];
          environment = {
            PORT = toString port;
            NIXERY_CHANNEL = channel;
            NIXERY_STORAGE_BACKEND = "filesystem";
            STORAGE_PATH = "/var/lib/nixery";
            NIX_TIMEOUT = "60";
          };
          serviceConfig = {
            ExecStart =
              let
                nixeryOutputs = import "${inputs.nixery}/default.nix" { inherit pkgs; };
                nixeryServer = pkgs.writeShellScriptBin "nixery-server" ''
                  export PATH="${nixeryOutputs.nixery-prepare-image}/bin:${pkgs.nix}/bin:$PATH"
                  exec ${nixeryOutputs.nixery}/bin/server "$@"
                '';
              in
              "${nixeryServer}/bin/nixery-server";
            Restart = "always";
            DynamicUser = true;
            StateDirectory = "nixery";
          };
        };

      };
  };
}
