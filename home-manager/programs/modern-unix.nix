{pkgs, ...}: {
  home.packages = with pkgs; [
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
    ouch
    silver-searcher
    thefuck
    procs
    psensor
    trash-cli
    ripgrep
    sd
    xcp
    yq
  ];
}
