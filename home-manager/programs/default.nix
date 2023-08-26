{pkgs, ...}: {
  imports = [
    ./bat.nix
    ./bottom.nix
    ./calcure.nix
    ./exa.nix
    ./devenv.nix
    ./dooit.nix
    ./fzf.nix
    ./git.nix
    ./gpg.nix
    ./starship.nix
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

  home.packages = with pkgs; [
    #tmp
    cargo
    rustc
    go

    nix-init
    nix-update
    any-nix-shell

    moreutils
    nvtop-amd
    htop
    ranger
    lf
    ctpv
    unzip
    pavucontrol
    gnupg
    ferdium

    # other
    brotab
    betterdiscord-installer
    discord
    showmethekey

    # modern "unix" tools
    broot
    choose
    curlie
    dog
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
    lazydocker
    killall
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
    chafa
    charasay
    fortune
    lolcat
    neofetch
    sl
  ];
}
