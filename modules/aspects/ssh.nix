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
          matchBlocks = {
            "*" = {
              addKeysToAgent = "yes";
              identitiesOnly = true;
              serverAliveInterval = 60;
              serverAliveCountMax = 3;
            };
            "git.haseebmajid.dev" = {
              hostname = "git.haseebmajid.dev";
              user = "git";
              port = 22;
              proxyCommand = "${pkgs.cloudflared}/bin/cloudflared access ssh --hostname %h";
            };
          };
          extraConfig = ''
            KexAlgorithms sntrup761x25519-sha512@openssh.com,curve25519-sha256,curve25519-sha256@libssh.org
          '';
        };
      };
  };
}
