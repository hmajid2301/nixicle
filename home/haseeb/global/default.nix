{ inputs, lib, pkgs, config, outputs, ... }:
let
  inherit (inputs.nix-colors) colorSchemes;
  #inherit (inputs.nix-colors.lib-contrib { inherit pkgs; }) colorschemeFromPicture nixWallpaperFromScheme;
in
{
  imports = [
    inputs.nix-colors.homeManagerModule
    ../features/editors/nvim
    ../features/packages/coding.nix
    ../features/packages/other.nix
    ../features/programs/cli.nix
  ] ++ (builtins.attrValues outputs.homeManagerModules);

  nixpkgs = {
    overlays = builtins.attrValues outputs.overlays;
    config = {
      allowUnfree = true;
      allowUnfreePredicate = (_: true);
    };
  };

  nix = {
    package = lib.mkDefault pkgs.nix;
    settings = {
      experimental-features = [ "nix-command" "flakes" "repl-flake" ];
      warn-dirty = false;
    };
  };

  systemd.user.startServices = "sd-switch";

  programs = {
    home-manager.enable = true;
    git.enable = true;
  };

  home = {
    username = lib.mkDefault "haseeb";
    homeDirectory = lib.mkDefault "/home/${config.home.username}";
    stateVersion = lib.mkDefault "22.05";
    sessionPath = [ "$HOME/.local/bin" ];
  };

  #wallpaper =
  #  let
  #    largest = f: xs: builtins.head (builtins.sort (a: b: a > b) (map f xs));
  #    largestWidth = largest (x: x.width) config.monitors;
  #    largestHeight = largest (x: x.height) config.monitors;
  #  in
  #  lib.mkDefault (nixWallpaperFromScheme
  #    {
  #      scheme = config.colorscheme;
  #      width = largestWidth;
  #      height = largestHeight;
  #      logoScale = 4;
  #    });
}

