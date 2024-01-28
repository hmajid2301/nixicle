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
      "zellij/layouts/zjstatus.kdl".text = ''
        layout {
         tab {
        	 pane
         }

         default_tab_template {
        	 pane size=1 borderless=true {
        		 plugin location="file:${inputs.zjstatus.packages.${pkgs.system}.default}/bin/zjstatus.wasm" {
        			 format_left "{tabs}"
        			 format_right "{mode}#[bg=#f5c2e7,fg=#000000,bold]  #[bg=#313244,bold] {session} "

        			 mode_normal        "#[fg=#b8bb26,bold]{name}"
        			 mode_locked        "#[fg=#fb4934,bold]{name}"
        			 mode_resize        "#[fg=#fabd2f,bold]{name}"
        			 mode_pane          "#[fg=#d3869b,bold]{name}"
        			 mode_tab           "#[fg=#83a598,bold]{name}"
        			 mode_scroll        "#[fg=#8ec07c,bold]{name}"
        			 mode_session       "#[fg=#fe8019,bold]{name}"
        			 mode_move          "#[fg=#a89984,bold]{name}"

        			 tab_normal   "#[fg=#fab387,bold] {name}"
        			 tab_active   "#[fg=#89b4fa,bold] {name}"
        		 }
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
