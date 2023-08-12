{ pkgs, ... }:

{
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
    ./lazygit.nix
    ./starship.nix
    ./tmux.nix
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
    nix-init
    nix-update

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
    mcfly
    ouch
    silver-searcher
    thefuck
    procs
    psensor
    shell-genie
    ripgrep-all
    ripgrep # for neovim
    tokei
    trash-cli
    sd
    xcp
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
    charasay
    fortune
    lolcat
    neofetch
    sl
  ];
}

