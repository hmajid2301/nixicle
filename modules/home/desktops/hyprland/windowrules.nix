{
  pkgs,
  config,
  lib,
  ...
}:
with lib; let
  rule = rules: attrs: attrs // {inherit rules;};
  cfg = config.desktops.hyprland;
in {
  config = mkIf cfg.enable {
    wayland.windowManager.hyprland.windowRules = let
      firefoxVideo = {
        class = ["firefox"];
      };
      guildWars = {
        title = ["Guild Wars 2"];
      };
      bitwarden = {
        title = [".*Bitwarden.*"];
      };
    in
      lib.concatLists [
        (map (rule ["idleinhibit fullscreen"]) [firefoxVideo])
        (map (rule ["fullscreen"]) [guildWars])
        (map (rule ["float"]) [bitwarden])
      ];
  };
}
