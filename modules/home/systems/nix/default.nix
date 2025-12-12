{
  config,
  pkgs,
  lib,
  ...
}:
with lib;
with lib.nixicle;

let
  cfg = config.system.nix;
in
{
  options.system.nix = with types; {
    enable = mkBoolOpt false "Whether or not to manage nix configuration";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      nixgl.nixGLIntel
      nvd
    ];

    systemd.user.startServices = "sd-switch";

    programs = {
      home-manager.enable = true;
    };

    home.sessionVariables = {
      NH_FLAKE = "/home/${config.nixicle.user.name}/nixicle";
    };

    nix = {
      package = lib.mkDefault pkgs.nix;

      settings = lib.mkIf (config.targets.genericLinux.enable or false) {
        trusted-substituters = [
          "https://cache.nixos.org"
          "https://nix-community.cachix.org"
          "https://numtide.cachix.org?priority=42"
        ];

        trusted-public-keys = [
          "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
          "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
          "numtide.cachix.org-1:2ps1kLBUWjxIneOy1Ik6cQjb41X0iXVXeHigGmycPPE="
        ];

        experimental-features = [
          "nix-command"
          "flakes"
        ];
        warn-dirty = false;
        use-xdg-base-directories = true;
      };
    };

    news = {
      display = "silent";
      json = lib.mkForce { };
      entries = lib.mkForce [ ];
    };

    # Clean up dead symlinks in systemd user directory
    home.activation.cleanupDeadSymlinks = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      if [ -d "$HOME/.config/systemd/user" ]; then
        $DRY_RUN_CMD ${pkgs.findutils}/bin/find "$HOME/.config/systemd/user" -maxdepth 1 -xtype l -delete
        $VERBOSE_ECHO "Cleaned up dead symlinks in systemd user directory"
      fi
    '';
  };
}
