{pkgs, ...}: let
  hostname = "three";
in {
  networking = {
    hostName = hostname;
  };

  nix.settings.trusted-users = [hostname];
  services.k3s.role = "agent";
  services.k3s.serverAddr = "https://one:6443";

  users = {
    #mutableUsers = false;
    users."${hostname}" = {
      isNormalUser = true;
      shell = pkgs.fish;
      extraGroups = ["wheel"];
      password = hostname;
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKuM4bCeJq0XQ1vd/iNK650Bu3wPVKQTSB0k2gsMKhdE hello@haseebmajid.dev"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINP5gqbEEj+pykK58djSI1vtMtFiaYcygqhHd3mzPbSt hello@haseebmajid.dev"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHiXSCUnfGG1lxQW470+XBiDgjyYOy5PdHdXsmpraRei haseeb.majid@imaginecurve.com"
      ];
    };
  };
}
