{ den, ... }:
{
  den.aspects.common = {
    nixos = { ... }: {
      hardware.networking.enable = true;
      services.ssh.enable = true;
      security = {
        sops.enable = true;
        yubikey.enable = true;
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

    homeManager = { ... }: {
      home.sessionVariables.NH_SEARCH_CHANNEL = "nixos-unstable";
      browsers.firefox.enable = true;
      system.nix.enable = true;
      cli = {
        terminals.foot.enable = true;
        terminals.ghostty.enable = true;
        tools.core-tools.enable = true;
        tools.zk.enable = true;
        shells.fish.enable = true;
      };
      development.cloud.k8s.enable = true;
      programs = {
        guis.enable = true;
        nautilus.enable = true;
      };
      security.sops.enable = true;
      hardware.zsa-keyboard.enable = true;
      styles.stylix.enable = true;
    };
  };
}
