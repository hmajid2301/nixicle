{delib, ...}:
delib.module {
  name = "cli-tools-yazi";

  options.cli.tools.yazi = with delib; {
    enable = boolOption false;
  };

  home.always = {config, lib, pkgs, ...}:
  with lib;
  with lib.nixicle;
  let
    cfg = config.cli.tools.yazi;
  in
  mkIf cfg.enable {
    programs.yazi = {
      enable = true;
      enableFishIntegration = true;
    };

    home.packages = with pkgs; [
      imagemagick
      ffmpegthumbnailer
      fontpreview
      unar
      poppler
      unar
    ];
  };
}
