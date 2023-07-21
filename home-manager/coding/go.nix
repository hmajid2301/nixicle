{ config, pkgs, ... }:

{
  # TODO: define GOPATH here?
  home.packages = with pkgs; [
    go
  ];
}
