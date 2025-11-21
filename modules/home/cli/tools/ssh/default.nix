{
  config,
  lib,
mkOpt ? null,
mkBoolOpt ? null,
enabled ? null,
disabled ? null,
  ...
}:
with lib;

let
  cfg = config.cli.tools.ssh;
in
{
  options.cli.tools.ssh = with types; {
    enable = mkBoolOpt false "Whether or not to enable ssh";
    enableKeychain = mkBoolOpt true "Whether to enable keychain for SSH key management";
  };

  config = mkIf cfg.enable {
    programs.keychain = mkIf cfg.enableKeychain {
      enable = true;
      keys = [ "id_ed25519" ];
    };

    programs.ssh = {
      enable = true;
      enableDefaultConfig = false;
      matchBlocks."*" = {
        addKeysToAgent = "yes";
        # Common default SSH options
        identitiesOnly = true;
        serverAliveInterval = 60;
        serverAliveCountMax = 3;
      };
    };
  };
}
