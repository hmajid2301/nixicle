{delib, ...}:
delib.module {
  name = "security-sops";

  options.security.sops = with delib; {
    enable = boolOption false;
  };

  # Note: sops-nix home module is imported via flake extraModules
  home.always = {config, lib, inputs, ...}:
  with lib;
  with lib.nixicle;
  let
    cfg = config.security.sops;
  in
  mkIf cfg.enable {
    sops = {
      age = {
        generateKey = true;
        keyFile = "/home/${config.nixicle.user.name}/.config/sops/age/keys.txt";
        sshKeyPaths = ["/home/${config.nixicle.user.name}/.ssh/id_ed25519"];
      };

      defaultSymlinkPath = "/run/user/1000/secrets";
      defaultSecretsMountPoint = "/run/user/1000/secrets.d";
    };
  };
}
