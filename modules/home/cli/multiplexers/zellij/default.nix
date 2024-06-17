{
  pkgs,
  lib,
  config,
  ...
}:
with lib;
with lib.nixicle; let
  cfg = config.cli.multiplexers.zellij;
in {
  options.cli.multiplexers.zellij = with types; {
    enable = mkBoolOpt false "enable zellij multiplexer";
  };

  config = mkIf cfg.enable {
    home.packages = [
      pkgs.tmate
    ];

    xdg.configFile = {
      "zellij/config.kdl".source = ./config.kdl;
      "zellij/layouts/mine.kdl".text = ''
        layout {
        	pane size=1 borderless=true {
        		plugin location="zellij:compact-bar"
        	}
        	pane
        }
      '';
    };

    programs.zellij = {
      enable = true;
    };
  };
}
