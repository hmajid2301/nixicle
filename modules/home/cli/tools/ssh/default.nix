{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
with lib.nixicle;

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
      matchBlocks = {
        "*" = {
          addKeysToAgent = "yes";
          identitiesOnly = true;
          serverAliveInterval = 60;
          serverAliveCountMax = 3;
        };

        # Tangled Git server via Cloudflare tunnel
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
}
