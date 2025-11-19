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
  cfg = config.cli.tools.yazi;
in {
  options.cli.tools.yazi = with types; {
    enable = mkBoolOpt false "Whether or not to enable yazi";
  };

  config = mkIf cfg.enable {
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
