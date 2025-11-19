{delib, ...}:
delib.module {
  name = "cli-tools-homelab";

  options.cli.tools.homelab = with delib; {
    enable = boolOption false;
  };

  home.always = {config, lib, pkgs, ...}:
  with lib;
  with lib.nixicle;
  let
    cfg = config.cli.tools.homelab;
  in
  mkIf cfg.enable {
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
