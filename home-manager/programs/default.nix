{ inputs, pkgs, lib, ... }: {
  imports = [
    ./attic.nix
    ./atuin.nix
    ./bat.nix
    ./bottom.nix
    ./cheat-sheet.nix
    ./direnv.nix
    ./discord.nix
    ./eza.nix
    ./fonts.nix
    ./fzf.nix
    ./git.nix
    ./gpg.nix
    ./k8s.nix
    ./kafka.nix
    ./kdeconnect.nix
    ./modern-unix.nix
    ./yazi.nix
    ./photos.nix
    ./starship.nix
    ./spotify.nix
    ./zoxide.nix
  ];

  programs.nix-index = {
    enable = true;
    enableFishIntegration = true;
  };

  home.packages = with pkgs; [
    keymapp
    powertop

    nix-init
    nix-update
    nix-your-shell
    src-cli

    (lib.hiPrio parallel)
    moreutils
    nvtop-amd
    htop
    ctpv
    unzip
    pavucontrol
    gnupg

    showmethekey

    # cheat sheets
    cheat
    cht-sh
    navi
    tealdeer
  ];
}
