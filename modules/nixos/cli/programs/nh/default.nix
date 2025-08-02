{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
with lib.nixicle;
let
  cfg = config.cli.programs.nh;
in
{
  options.cli.programs.nh = with types; {
    enable = mkBoolOpt false "Whether or not to enable nh.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      (pkgs.nix-output-monitor.overrideAttrs (old: {
        postPatch = old.postPatch or "" + ''
          sed -ie ${lib.escapeShellArg ''
            s/↓/\\xf072e/
            s/↑/\\xf0737/
            s/⏱/\\xf520/
            s/⏵/\\xf04b/
            s/✔/\\xf00c/
            s/⏸/\\xf04d/
            s/⚠/\\xf071/
            s/∅/\\xf1da/
            s/∑/\\xf04a0/
          ''} lib/NOM/Print.hs
        '';
      }))
    ];

    programs.nh = {
      enable = true;
      clean.enable = true;
      clean.extraArgs = "--keep-since 4d --keep 3";
      flake = "/home/${config.user.name}/nixicle";
    };
  };
}
