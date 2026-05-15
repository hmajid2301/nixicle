{ ... }:
let
  tunnelId = "ecef5dbb-834e-43ed-84c6-355a2ac53e59";
in
{
  den.aspects.atuin = {
    includes = [ ];
    persist.directories = [ "/var/lib/atuin" ];
    nixos =
      { ... }:
      {
        services.atuin = {
          enable = true;
          openRegistration = true;
          maxHistoryLength = 99999999;
          port = 8890;
        };

        services.cloudflared.tunnels.${tunnelId}.ingress."atuin.haseebmajid.dev" = "http://localhost:8890";

      };
  };
}
