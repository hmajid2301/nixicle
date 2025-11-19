{
  config,
  lib,
  pkgs,
mkOpt ? null,
mkBoolOpt ? null,
enabled ? null,
disabled ? null,
  ...
}:
with lib;

let
  cfg = config.cli.programs.nh;
in
{
  options.cli.programs.nh = with types; {
    enable = mkBoolOpt false "Whether or not to enable nh.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      (pkgs.nh.override {
        nix-output-monitor = pkgs.nix-output-monitor.overrideAttrs (old: {
          postPatch = old.postPatch or "" + ''
            substituteInPlace lib/NOM/Print.hs \
              --replace 'down = "↓"' 'down = "\xf072e"' \
              --replace 'up = "↑"' 'up = "\xf0737"' \
              --replace 'clock = "⏱"' 'clock = "\xf520"' \
              --replace 'running = "⏵"' 'running = "\xf04b"' \
              --replace 'done = "✔"' 'done = "\xf00c"' \
              --replace 'todo = "⏸"' 'todo = "\xf04d"' \
              --replace 'warning = "⚠"' 'warning = "\xf071"' \
              --replace 'average = "∅"' 'average = "\xf1da"' \
              --replace 'bigsum = "∑"' 'bigsum = "\xf04a0"'
          '';
        });
      })
    ];

    programs.nh = {
      enable = true;
      clean.enable = true;
      clean.extraArgs = "--keep-since 4d --keep 3";
      flake = "/home/${config.user.name}/nixicle";
    };
  };
}
