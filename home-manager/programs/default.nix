{ pkgs, ... }: {
  imports = [
    ./bat.nix
    ./bottom.nix
    ./calcure.nix
    ./eza.nix
    ./foliate.nix
    ./direnv.nix
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
    dooit

    ventoy-full

    nix-init
    nix-update
    nix-your-shell

    # sourcegraph
    src-cli

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
    fontforge
    thunderbird-unwrapped

    # modern "unix" tools
    broot
    choose
    curlie
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
