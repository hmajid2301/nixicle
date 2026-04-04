{ den, lib, ... }:
{
  den.aspects.haseeb = {
    includes = [
      ({ user, ... }: {
        nixos.users.users.haseeb.openssh.authorizedKeys.keys = user.authorizedKeys;
        nixos.users.users.root.openssh.authorizedKeys.keys = user.authorizedKeys;
        nixos.home-manager.users.haseeb.programs.git = {
          settings.user.email = lib.mkForce user.email;
          signing.key = lib.mkForce user.signingKey;
        };
      })
    ];

    homeManager = { ... }: {
      gtk.gtk4.theme = null;
      programs.git.signing = {
        format = "ssh";
        signByDefault = true;
      };
    };
  };
}
