{ den, ... }:
{
  den.aspects.common = {
    includes = [ den.aspects.stylix ];

    nixos = { ... }: {
      hardware.networking.enable = true;

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
      };

      security = {
        sops.enable = true;
        yubikey.enable = true;
        sudo.extraConfig = ''
          Defaults secure_path="/run/wrappers/bin:/run/current-system/sw/bin:/nix/var/nix/profiles/default/bin:/usr/local/bin:/usr/bin:/bin"
        '';
      };
      system = {
        nix.enable = true;
        boot.enable = true;
        locale.enable = true;
      };
    };

    homeManager = { ... }: {
      home.sessionVariables.NH_SEARCH_CHANNEL = "nixos-unstable";
      browsers.firefox.enable = true;
      system.nix.enable = true;
      cli = {
        terminals.foot.enable = true;
        terminals.ghostty.enable = true;
        tools.core-tools.enable = true;
        tools.zk.enable = true;
        shells.fish.enable = true;
      };
      development.cloud.k8s.enable = true;
      programs = {
        guis.enable = true;
        nautilus.enable = true;
      };
      security.sops.enable = true;
      hardware.zsa-keyboard.enable = true;
    };
  };
}
