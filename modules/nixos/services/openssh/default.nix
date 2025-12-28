{
  config,
  lib,
  ...
}:
with lib;
with lib.nixicle;
let
  cfg = config.services.ssh;
in
{
  options.services.ssh = with types; {
    enable = mkBoolOpt false "Enable ssh";
    authorizedKeys = mkOpt (listOf str) [ ] "The public keys to apply.";
  };

  config = mkIf cfg.enable {
    services.openssh = {
      enable = true;
      ports = [ 22 ];

      settings = {
        PasswordAuthentication = false;
        PermitRootLogin = "prohibit-password";
        StreamLocalBindUnlink = "yes";
        GatewayPorts = "clientspecified";

        KexAlgorithms = [
          "sntrup761x25519-sha512@openssh.com"
          "curve25519-sha256"
          "curve25519-sha256@libssh.org"
        ];

        Ciphers = [
          "chacha20-poly1305@openssh.com"
          "aes256-gcm@openssh.com"
          "aes128-gcm@openssh.com"
        ];

        Macs = [
          "hmac-sha2-512-etm@openssh.com"
          "hmac-sha2-256-etm@openssh.com"
        ];
      };

      extraConfig = mkIf config.services.nixicle.tailscale.enable ''
        Match Address 100.64.0.0/10
          AllowTcpForwarding yes
          AllowAgentForwarding yes
      '';
    };

    users.users = {
      ${config.user.name}.openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKuM4bCeJq0XQ1vd/iNK650Bu3wPVKQTSB0k2gsMKhdE hello@haseebmajid.dev"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINP5gqbEEj+pykK58djSI1vtMtFiaYcygqhHd3mzPbSt hello@haseebmajid.dev"
      ];
      root.openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKuM4bCeJq0XQ1vd/iNK650Bu3wPVKQTSB0k2gsMKhdE hello@haseebmajid.dev"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINP5gqbEEj+pykK58djSI1vtMtFiaYcygqhHd3mzPbSt hello@haseebmajid.dev"
      ];
    };
  };
}
