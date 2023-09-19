{ pkgs
, inputs
, ...
}: {
  nix.settings = {
    extra-substituters = [
      "https://majiy00-nix-binary-cache.fly.dev/prod"
    ];
    extra-trusted-public-keys = [
      "prod:fjP15qp9O3/x2WTb1LiQ2bhjxkBBip3uhjlDyqywz3I="
    ];
  };

  imports = [ inputs.attic.nixosModules.atticd ];

  environment.systemPackages = with pkgs; [
    attic
  ];


  systemd.services.attic-watch-store = {
    wantedBy = [ "multi-user.target" ];
    after = [ "network-online.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.attic}/bin/attic watch-store prod:prod";
      Restart = "on-failure";
      ProtectKernelLogs = true;
      ProtectKernelModules = true;
      ProtectKernelTunables = true;
      ProtectProc = "invisible";
      ProtectSystem = "strict";
      RestrictAddressFamilies = [ "AF_INET" "AF_INET6" "AF_UNIX" ];
      RestrictNamespaces = true;
      RestrictRealtime = true;
      RestrictSUIDSGID = true;
    };
  };
}
