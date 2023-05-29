{ pkgs, ... }:

{
  xdg.configFile."." = {
    source = ./config;
    recursive = true;
  };

  programs.zoxide = {
    enable = true;
    enableFishIntegration = true;
  };

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
    erdtree
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
    ouch
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

