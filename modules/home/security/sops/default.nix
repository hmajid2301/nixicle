{
  config,
  lib,
  inputs,
  ...
}:
with lib;
with lib.nixicle;
let
  cfg = config.security.sops;
in
{
  options.security.sops = with types; {
    enable = mkBoolOpt false "Whether to enable sop for secrets management.";
  };

  imports = with inputs; [
    sops-nix.homeManagerModules.sops
  ];

  config = mkIf cfg.enable {
    sops = {
      age = {
        generateKey = true;
        keyFile = "/home/${config.home.username}/.config/sops/age/keys.txt";
        sshKeyPaths = [ "/home/${config.home.username}/.ssh/id_ed25519" ];
      };

      defaultSymlinkPath = "/run/user/1000/secrets";
      defaultSecretsMountPoint = "/run/user/1000/secrets.d";
    };
  };
}
