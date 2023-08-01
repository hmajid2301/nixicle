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
    age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
  };
  home.packages = with pkgs; [
    sops
  ];
}

