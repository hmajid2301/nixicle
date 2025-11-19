{delib, ...}:
delib.module {
  name = "cli-tools-network-tools";

  options.cli.tools.network-tools = with delib; {
    enable = boolOption false;
  };

  home.always = {config, lib, pkgs, ...}:
  with lib;
  with lib.nixicle;
  let
    cfg = config.cli.tools.network-tools;
  in
  mkIf cfg.enable {
    home.packages = with pkgs; [
      tshark
      termshark
      kubeshark
    ];
  };
}
