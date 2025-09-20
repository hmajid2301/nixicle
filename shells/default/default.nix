{
  pkgs,
  inputs,
  ...
}:
pkgs.mkShell {
  NIX_CONFIG = "extra-experimental-features = nix-command flakes";

  packages = with pkgs; [
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
    inputs.nixos-anywhere.packages.${pkgs.system}.nixos-anywhere
    deploy-rs

    statix
    deadnix
    alejandra
    home-manager
    git
    sops
    ssh-to-age
    gnupg
    age
    opentofu
    mc
  ];
}
