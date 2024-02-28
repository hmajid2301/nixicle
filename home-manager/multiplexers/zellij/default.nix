{
  inputs,
  pkgs,
  lib,
  config,
  ...
}:
with lib; let
  cfg = config.modules.multiplexers.zellij;
  inherit (config.colorscheme) colors;
in {
  options.modules.multiplexers.zellij = {
    enable = mkEnableOption "enable zellij multiplexer";
  };

  config = mkIf cfg.enable {
    home.packages = [
      pkgs.tmate
      inputs.zjstatus.packages.${pkgs.system}.default
    ];

    xdg.configFile = {
      "zellij/config.kdl".source = ./config.kdl;
      "zellij/layouts/mine.kdl".text = ''
        layout {
         tab {
        	 pane
         }

         default_tab_template {
        	 pane size=1 borderless=true {
        		 plugin location="zellij:compact-bar"
        	 }
        	 children
         }
        }
      '';
    };

    programs.zellij = {
      enable = true;
    };
  };
}
