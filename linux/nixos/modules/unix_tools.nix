{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    # modern "unix" tools
    bat
    bottom
    broot
    choose
    curlie
    dog
    duf
    entr
    exa
    fd
    fzf
    delta
    gdu
    go-task
    gping
    hyperfine
    lazydocker
    lazygit
    mcfly
    silver-searcher
    thefuck
    procs
    psensor
    ripgrep-all
    ripgrep # for neovim
    starship
    trash-cli
    sd
    yq
    zoxide

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
    fortune
    lolcat
    neofetch
    sl
    # for sunpaper
    sunwait
    wallutils
  ];
}

