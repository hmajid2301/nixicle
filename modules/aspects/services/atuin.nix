{ den, ... }:
let
  tunnelId = "ecef5dbb-834e-43ed-84c6-355a2ac53e59";
in
{
  den.aspects.atuin = {
    nixos = { config, lib, ... }: {
      services.atuin = {
        enable = true;
        openRegistration = true;
        maxHistoryLength = 99999999;
        port = 8890;
      };

      services.cloudflared.tunnels.${tunnelId}.ingress."atuin.haseebmajid.dev" = "http://localhost:8890";

      environment.persistence."/persist".directories =
        lib.mkIf config.system.impermanence.enable [ "/var/lib/atuin" ];
    };
  };
}
