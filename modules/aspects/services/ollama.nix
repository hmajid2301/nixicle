{ ... }:
{
  den.aspects.ollama = {
    includes = [ ];
    backup.ollama.paths = [ "/var/lib/ollama" ];
    persist.directories = [
      {
        directory = "/var/lib/ollama";
        user = "ollama";
        group = "ollama";
        mode = "0750";
      }
    ];

    nixos =
      { lib, ... }:
      {
        services = {
          ollama = {
            enable = true;
            user = "ollama";
            group = "ollama";
            # host defaults to 127.0.0.1 — only accessible via localhost
            # port defaults to 11434
          };
        };

        # DynamicUser conflicts with our static user + persist setup.
        # The NixOS module hardcodes DynamicUser=true; force it off.
        systemd.services.ollama = {
          serviceConfig.DynamicUser = lib.mkForce false;
          # ReadWritePaths includes modelsDir (/var/lib/ollama/models) by default,
          # which fails mount namespace setup because the dir doesn't exist yet.
          # Override to only include the home dir (already created by persist).
          serviceConfig.ReadWritePaths = lib.mkForce [ "/var/lib/ollama" ];
        };

        users.users.ollama = {
          isSystemUser = true;
          group = "ollama";
        };
        users.groups.ollama = { };
      };
  };
}
