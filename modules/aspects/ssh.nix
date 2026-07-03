{ ... }:
{
  den.aspects.ssh = {
    homeManager =
      { pkgs, ... }:
      {
        programs.keychain = {
          enable = true;
          keys = [ "id_ed25519" ];
        };

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
            "git.haseebmajid.dev" = {
              HostName = "git.haseebmajid.dev";
              User = "git";
              Port = 2222;
            };
          };
          extraConfig = ''
            KexAlgorithms sntrup761x25519-sha512@openssh.com,curve25519-sha256,curve25519-sha256@libssh.org
          '';
        };
      };
  };
}
