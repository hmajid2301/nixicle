{
  config,
  lib,
  ...
}:
with lib;
with lib.nixicle; let
  cfg = config.system.nix;
in {
  options.system.nix = with types; {
    enable = mkBoolOpt false "Whether or not to manage nix configuration";
  };

  config = mkIf cfg.enable {
    nix = {
      settings = {
        trusted-users = ["@wheel" "root"];
        auto-optimise-store = lib.mkDefault true;
        use-xdg-base-directories = true;
        experimental-features = ["nix-command" "flakes"];
        warn-dirty = false;
        system-features = ["kvm" "big-parallel" "nixos-test"];
        # Disable global flake registry (old URL is 404)
        flake-registry = "";
      };
    };
  };
}
