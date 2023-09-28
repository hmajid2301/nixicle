{ pkgs
, config
, inputs
, ...
}: {
  nix.settings = {
    extra-substituters = [
      "https://majiy00-nix-binary-cache.fly.dev"
      "https://cache.saumon.network/camille"
    ];
    extra-trusted-public-keys = [
      "prod:fjP15qp9O3/x2WTb1LiQ2bhjxkBBip3uhjlDyqywz3I="
    ];
  };

  imports = [ inputs.attic.nixosModules.atticd ];

  environment.systemPackages = with pkgs; [
    attic
  ];

  sops.secrets.attic_auth_token = {
    sopsFile = ../../hosts/iso/secrets.yaml;
    neededForUsers = true;
  };

  systemd.services.attic-watch-store = {
    wantedBy = [ "multi-user.target" ];
    after = [ "network-online.target" ];
    serviceConfig = {
      MemoryHigh = "5%";
      MemoryMax = "10%";
    };

    script = ''
      #!/run/current-system/sw/bin/bash
      ATTIC_TOKEN=$(cat ${config.sops.secrets.attic_auth_token.path})
      ${pkgs.attic}/bin/attic login prod https://majiy00-nix-binary-cache.fly.dev $ATTIC_TOKEN
      ${pkgs.attic}/bin/attic use prod
      ${pkgs.attic}/bin/attic watch-store prod:prod
    '';
  };
}
