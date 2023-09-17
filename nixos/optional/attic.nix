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
}
