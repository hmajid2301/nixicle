{inputs, ...}: {
  imports = [
    inputs.impermanence.nixosModules.impermanence
  ];

  environment.persistence = {
    "/persist" = {
      hideMounts = true;
      directories = [
        "/srv"
        "/etc/ssh"
        "/var/lib/systemd"
        "/var/lib/nixos"
        "/var/lib/cups"
        "/var/lib/fprint"
        "/var/db/sudo/lectured"
        "/home/haseeb"
      ];
      files = [
        "/etc/machine-id"
        "/etc/nix/id_rsa"
      ];
    };
  };
  programs.fuse.userAllowOther = true;
}
