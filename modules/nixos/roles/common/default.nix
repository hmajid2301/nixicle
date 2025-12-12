{
  lib,
  config,
  ...
}:
with lib; let
  cfg = config.roles.common;
in {
  options.roles.common = {
    enable = mkEnableOption "Enable common configuration";
  };

  config = mkIf cfg.enable {
    hardware = {
      networking.enable = true;
    };

    services = {
      ssh.enable = true;
    };

    security = {
      sops.enable = true;
      yubikey.enable = true;
      # Ensure sudo preserves PATH for nix commands
      sudo.extraConfig = ''
        Defaults secure_path="/run/wrappers/bin:/run/current-system/sw/bin:/nix/var/nix/profiles/default/bin:/usr/local/bin:/usr/bin:/bin"
      '';
    };

    system = {
      nix.enable = true;
      boot.enable = true;
      locale.enable = true;
    };
    styles.stylix.enable = true;
  };
}
