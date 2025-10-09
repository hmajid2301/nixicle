{
  pkgs,
  config,
  lib,
  ...
}:
with lib;
with lib.nixicle;
let
  cfg = config.cli.programs.homelab;
in
{
  options.cli.programs.homelab = with types; {
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