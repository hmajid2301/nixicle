{
  pkgs,
  config,
  lib,
mkOpt ? null,
mkBoolOpt ? null,
enabled ? null,
disabled ? null,
  ...
}:
with lib;

let
  cfg = config.cli.tools.homelab;
in
{
  options.cli.tools.homelab = with types; {
    enable = mkBoolOpt false "Whether or not to enable homelab and infrastructure tools";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      # Database tools
      pgcli

      # Infrastructure and secrets
      openbao

      # Container and orchestration
      kind

      # Kafka and messaging
      kaf
    ];
  };
}