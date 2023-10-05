{ inputs, ... }: {
  imports = [
    inputs.impermanence.nixosModules.impermanence
  ];

  environment.persistence = {
    "/persist" = {
      directories = [
        "/srv"
        "/etc/ssh"
        "/var/lib/systemd"
        "/var/lib/nixos"
        "/var/lib/cups"
        "/var/lib/fprint"
        "/var/db/sudo/lectured"
        "/home"
      ];
      files = [
        "/etc/machine-id"
        "/etc/nix/id_rsa"
        "/var/lib/cups/printers.conf"
        "/var/lib/logrotate.status"
      ];
    };
  };
  programs.fuse.userAllowOther = true;
}
