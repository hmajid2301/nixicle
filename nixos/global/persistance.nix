{ inputs, ... }: {
  imports = [
    inputs.impermanence.nixosModules.impermanence
  ];

  environment.persistence = {
    "/persist" = {
      directories = [
        "/var/lib/systemd"
        "/var/lib/nixos"
        "/var/log"
        "/srv"
        "/home/haseeb"
        "/etc/ssh"
        "/var/log"
        "/var/lib/cups"
        "/var/lib/fprint"
        "/var/db/sudo/lectured"
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
