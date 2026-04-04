{
  config,
  lib,
  ...
}:
with lib;
let
  cfg = config.services.nixicle.unbound;
in
{
  options.services.nixicle.unbound = {
    enable = mkEnableOption "Enable Unbound recursive DNS resolver";
  };

  config = mkIf cfg.enable {
    services.unbound = {
      enable = true;
      settings = {
        server = {
          interface = [ "127.0.0.1" ];
          port = 5335;

          do-ip4 = true;
          do-ip6 = true;
          do-udp = true;
          do-tcp = true;

          prefer-ip6 = false;

          harden-glue = true;
          harden-dnssec-stripped = true;
          use-caps-for-id = false;
          edns-buffer-size = 1232;
          prefetch = "yes";

          num-threads = 1;

          so-rcvbuf = "1m";

          private-address = [
            "192.168.0.0/16"
            "169.254.0.0/16"
            "172.16.0.0/12"
            "10.0.0.0/8"
            "fd00::/8"
            "fe80::/10"
          ];

          # Allow Tailscale CGNAT range
          private-domain = [ "ts.net" ];
        };
      };
    };

    environment.persistence."/persist" = mkIf config.system.impermanence.enable {
      directories = [
        "/var/lib/unbound"
      ];
    };
  };
}
