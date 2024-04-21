{
  pkgs,
  config,
  lib,
  ...
}:
with lib;
with lib.nixicle; let
  cfg = config.cli.programs.attic;
in {
  options.cli.programs.attic = with types; {
    enable = mkBoolOpt false "Whether or not to enable attic";
  };

  config = mkIf cfg.enable {
    sops.secrets.netrc = {
      sopsFile = ../../../secrets.yaml;
    };

    home.packages = with pkgs; [
      attic-client
    ];

    nix.settings = {
      trusted-substituters = [
        "https://staging.attic.rs/attic-ci"
        "https://majiy00-nix-binary-cache.fly.dev/system?priority=43"
      ];
      trusted-public-keys = [
        "attic-ci:U5Sey4mUxwBXM3iFapmP0/ogODXywKLRNgRPQpEXxbo="
        "system:DdaMnHcRKtgaov3GCR8mlrFuX90ShC2LkHv6kC7nluo="
      ];
      netrc-file = config.sops.secrets."netrc".path;
    };

    # systemd.user.services.attic-watch-store = {
    #   Unit = {
    #     Description = "Push nix store changes to attic binary cache.";
    #   };
    #   Install = {
    #     WantedBy = ["default.target"];
    #   };
    #   Service = {
    #     ExecStart = "${pkgs.writeShellScript "watch-store" ''
    #       #!/run/current-system/sw/bin/bash
    #       ATTIC_TOKEN=$(cat ${config.sops.secrets.attic_auth_token.path})
    #       ${pkgs.attic}/bin/attic login prod https://majiy00-nix-binary-cache.fly.dev $ATTIC_TOKEN
    #       ${pkgs.attic}/bin/attic use prod
    #       ${pkgs.attic}/bin/attic watch-store prod:prod
    #     ''}";
    #     MemoryHigh = "1.5G";
    #     MemoryMax = "2G";
    #   };
    # };
  };
}
