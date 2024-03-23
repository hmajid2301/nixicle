{
  pkgs,
  config,
  lib,
  inputs,
  ...
}:
with lib;
with lib.nixicle; let
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
      gnupg = {
        home = "~/.gnupg";
        sshKeyPaths = [];
      };
      defaultSymlinkPath = "/run/user/1000/secrets";
      defaultSecretsMountPoint = "/run/user/1000/secrets.d";
    };

    home.packages = with pkgs; [
      sops
    ];
  };
}
