{
  lib,
  pkgs,
  ...
}: {
  imports = lib.snowfall.fs.get-non-default-nix-files ./.;
}
