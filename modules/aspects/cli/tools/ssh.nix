_: {
  den.aspects.ssh = {
    homeManager = { lib, ... }: {
      services.ssh-agent.enable = true;

      programs.ssh = {
        enable = true;
        enableDefaultConfig = false;
        settings = {
          "*" = {
            AddKeysToAgent = "yes";
            IdentitiesOnly = true;
            ServerAliveInterval = 60;
            ServerAliveCountMax = 3;
          };
          "tangled.org" = {
            HostName = "tangled.org";
            User = "git";
            IdentityFile = "~/.ssh/id_ed25519";
            AddressFamily = "inet";
          };
          "knot.${lib.nixicle.domains.root}" = {
            HostName = "knot.${lib.nixicle.domains.root}";
            User = "git";
            Port = 2222;
            IdentityFile = "~/.ssh/id_ed25519";
            AddressFamily = "inet";
          };
          "git.${lib.nixicle.domains.root}" = {
            HostName = "git.${lib.nixicle.domains.root}";
            User = "git";
            Port = 22;
          };
        };
        extraConfig = ''
          KexAlgorithms sntrup761x25519-sha512@openssh.com,curve25519-sha256,curve25519-sha256@libssh.org
        '';
      };
    };
  };
}
