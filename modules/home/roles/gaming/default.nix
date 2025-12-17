{
  config,
  pkgs,
  lib,
  ...
}:
with lib;
with lib.nixicle;

let
  cfg = config.roles.gaming;
in
{
  options.roles.gaming = with types; {
    enable = mkBoolOpt false "Whether or not to manage gaming configuration";
  };

  config = mkIf cfg.enable {
    programs.mangohud = {
      enable = false;
      enableSessionWide = true;
      settings = {
        cpu_load_change = true;
      };
    };

    home.packages = with pkgs; [
      (lutris.override {
        extraPkgs = pkgs: [
          # Performance tools
          pkgs.gamemode
          pkgs.mangohud
          
          # GStreamer plugins and dependencies for Wine
          pkgs.gst_all_1.gstreamer
          pkgs.gst_all_1.gst-plugins-base
          pkgs.gst_all_1.gst-plugins-good
          pkgs.gst_all_1.gst-plugins-bad
          pkgs.gst_all_1.gst-plugins-ugly
          pkgs.gst_all_1.gst-libav
          
          # Missing libraries that Wine needs
          pkgs.libgudev
          pkgs.speex
          pkgs.libtheora
          pkgs.flac
          
          # Additional useful libraries
          pkgs.libva
          pkgs.libvdpau
        ];
      })
      bottles
    ];
  };
}
