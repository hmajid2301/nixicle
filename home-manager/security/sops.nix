{ inputs, pkgs, ... }:
{
  imports = [
    inputs.sops-nix.homeManagerModules.sops
  ];

  sops = {
    gnupg = {
      home = "~/.gnupg";
      sshKeyPaths = [ ];
    };
  };

  home.packages = with pkgs; [
    sops
  ];
}

