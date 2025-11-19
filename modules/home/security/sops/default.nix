{
  config,
  lib,
  inputs,
mkOpt ? null,
mkBoolOpt ? null,
enabled ? null,
disabled ? null,
  ...
}:
with lib;
 let
  cfg = config.security.sops;
in {
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
        keyFile = "/home/${config.nixicle.user.name}/.config/sops/age/keys.txt";
        sshKeyPaths = ["/home/${config.nixicle.user.name}/.ssh/id_ed25519"];
      };

      defaultSymlinkPath = "/run/user/1000/secrets";
      defaultSecretsMountPoint = "/run/user/1000/secrets.d";
    };
  };
}
