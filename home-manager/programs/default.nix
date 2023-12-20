{ inputs, pkgs, lib, ... }: {
  imports = [
    ./attic.nix
    ./atuin.nix
    ./bat.nix
    ./bottom.nix
    ./direnv.nix
    ./discord.nix
    ./eza.nix
    ./fonts.nix
    ./fzf.nix
    ./git.nix
    ./gpg.nix
    ./k8s.nix
    ./kafka.nix
    ./gaming.nix
    ./kdeconnect.nix
    ./yazi.nix
    ./photos.nix
    ./starship.nix
    ./spotify.nix
    ./zoxide.nix
  ];

  xdg.configFile."." = {
    source = ./config;
    recursive = true;
  };

  programs.nix-index = {
    enable = true;
    enableFishIntegration = true;
  };

  # programs.obs-studio = {
  #   enable = true;
  # };

  home.packages = with pkgs; [
    keymapp
    powertop

    #tmp
    cargo
    rustc

    nix-init
    nix-update
    nix-your-shell

    # sourcegraph
    src-cli

    (lib.hiPrio parallel)
    moreutils
    nvtop-amd
    htop
    ctpv
    unzip
    pavucontrol
    gnupg
    ferdium

    # other
    brotab
    showmethekey

    # modern "unix" tools
    broot
    choose
    curlie
    chafa
    dogdns
    duf
    delta
    du-dust
    dysk
    entr
    erdtree
    fd
    gdu
    gping
    hyperfine
    hexyl
    lazydocker
    ouch
    silver-searcher
    thefuck
    procs
    psensor
    shell-genie
    tokei
    trash-cli
    ripgrep
    sd
    xcp
    yq
    zk

    # cheat sheets
    cheat
    cht-sh
    navi
    tealdeer

    # for fun
    asciinema
    cava
    cmatrix
    charasay
    fortune
    lolcat
    neofetch
    sl
  ];
}
