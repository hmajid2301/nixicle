{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
with lib.nixicle;
let
  cfg = config.cli.tools.gsesh;
  gsesh = pkgs.callPackage ../../../../../packages/gsesh { };
in
{
  options.cli.tools.gsesh = {
    enable = mkEnableOption "Enable gsesh - Git session manager for worktrees + zellij";
  };

  config = mkIf cfg.enable {
    home.packages = [ gsesh ];
  };
}
