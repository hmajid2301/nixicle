{
  config,
  lib,
  ...
}:
with lib;
with lib.nixicle; let
  cfg = config.cli.programs.nh;
in {
  options.cli.programs.nh = with types; {
    enable = mkBoolOpt false "Whether or not to enable nh.";
  };

  config = mkIf cfg.enable {
    programs.nh = {
      enable = true;
      clean.enable = true;
      clean.extraArgs = "--keep-since 4d --keep 3";
      flake = "/home/${config.user.name}/nixicle";
    };
  };
}
