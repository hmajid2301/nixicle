
{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    # go
    go

    # c
    gcc

    # docker
    docker
    docker-compose
    podman

    # node
    nodePackages.pnpm
    nodejs

    # python
    python3Full

    # rust
    rustc
    cargo

    # parser (nvim)
    tree-sitter
  ];
}
