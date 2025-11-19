{delib, ...}:
delib.module {
  name = "cli-tools-ssh";

  options.cli.tools.ssh = with delib; {
    enable = boolOption false;
    enableKeychain = boolOption true;
  };

  home.always = {config, lib, ...}:
  with lib;
  with lib.nixicle;
  let
    cfg = config.cli.tools.ssh;
  in
  mkIf cfg.enable {
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
