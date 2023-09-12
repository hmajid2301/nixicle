{ lib
, pkgs
, config
, outputs
, ...
}:
{
  imports = [
    ./shells/fish.nix
    ./shells/zsh.nix
  ] ++ builtins.attrValues outputs.homeManagerModules;

  systemd.user.startServices = "sd-switch";

  programs = {
    home-manager.enable = true;
  };

  home.sessionVariables.EDITOR = config.my.settings.defaultEditor;

  nixpkgs = {
    overlays = builtins.attrValues outputs.overlays;
    config = {
      allowUnfree = true;
      allowUnfreePredicate = _: true;
    };
  };

  nix = {
    package = lib.mkDefault pkgs.nix;
    settings = {
      experimental-features = [ "nix-command" "flakes" "repl-flake" ];
      warn-dirty = false;
    };
  };
}
