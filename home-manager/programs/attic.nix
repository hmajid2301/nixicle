{ pkgs, config, ... }: {

  sops.secrets.attic_auth_token = {
    sopsFile = ../secrets.yaml;
  };

  #xdg.configFile."nix/netrc".source = config.sops.secrets.attic_auth_token.path;

  home.packages = with pkgs; [
    attic
  ];

  nix.settings = {
    extra-substituters = [
      "https://majiy00-nix-binary-cache.fly.dev"
    ];
    extra-trusted-public-keys = [
      "prod:fjP15qp9O3/x2WTb1LiQ2bhjxkBBip3uhjlDyqywz3I="
    ];
  };

  systemd.user.services.attic-watch-store = {
    Unit = {
      Description = "Push nix store changes to attic binary cache.";
    };
    Install = {
      WantedBy = [ "default.target" ];
    };
    Service = {
      ExecStart = "${pkgs.writeShellScript "watch-store" ''
				#!/run/current-system/sw/bin/bash
				ATTIC_TOKEN=$(cat ${config.sops.secrets.attic_auth_token.path})
				${pkgs.attic}/bin/attic login prod https://majiy00-nix-binary-cache.fly.dev $ATTIC_TOKEN
				${pkgs.attic}/bin/attic use prod
				${pkgs.attic}/bin/attic watch-store prod:prod
      ''}";
      MemoryHigh = "1.5G";
      MemoryMax = "2G";
    };
  };
}
