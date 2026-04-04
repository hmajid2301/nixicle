{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
with lib;
with lib.nixicle;
let
  cfg = config.services.nixicle.nixery;

  nixeryOutputs = import "${inputs.nixery}/default.nix" {
    inherit pkgs;
  };

  # Wrapper to inject dependencies into PATH
  nixeryServer = pkgs.writeShellScriptBin "nixery-server" ''
    export PATH="${nixeryOutputs.nixery-prepare-image}/bin:${pkgs.nix}/bin:$PATH"
    exec ${nixeryOutputs.nixery}/bin/server "$@"
  '';
in
{
  options.services.nixicle.nixery = {
    enable = mkBoolOpt false "Enable Nixery container registry";

    port = mkOpt types.port 8090 "Port for Nixery to listen on";

    storageBackend = mkOpt (types.enum [ "filesystem" "gcs" ]) "filesystem" "Storage backend to use";

    storagePath = mkOpt types.str "/var/lib/nixery" "Path for filesystem storage";

    channel = mkOpt types.str "nixos-unstable" "Nix/NixOS channel to use for builds";

    timeout = mkOpt types.int 60 "Builder timeout in seconds";
  };

  config = mkIf cfg.enable {
    systemd.services.nixery = {
      description = "Nixery Container Registry";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];

      environment = {
        PORT = toString cfg.port;
        NIXERY_CHANNEL = cfg.channel;
        NIXERY_STORAGE_BACKEND = cfg.storageBackend;
        STORAGE_PATH = cfg.storagePath;
        NIX_TIMEOUT = toString cfg.timeout;
      };

      serviceConfig = {
        ExecStart = "${nixeryServer}/bin/nixery-server";
        Restart = "always";
        DynamicUser = true;
        StateDirectory = "nixery";
      };
    };

    environment.persistence."/persist" = mkIf config.system.impermanence.enable {
      directories = [
        "/var/lib/private/nixery"
      ];
    };
  };
}
