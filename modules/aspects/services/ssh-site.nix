{
  inputs,
  ...
}:
{
  flake-file.inputs.ssh-site = {
    url = "git+https://gitlab.com/hmajid2301/ssh.haseebmajid.dev";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  den.aspects.ssh-site = {
    persist.directories = [
      {
        directory = "/var/lib/ssh-site";
        user = "ssh-site";
        group = "ssh-site";
        mode = "0700";
      }
    ];
    nixos =
      {
        pkgs,
        ...
      }:
      {
        imports = [ inputs.ssh-site.nixosModules.default ];

        services.ssh-site = {
          enable = true;
          package = inputs.ssh-site.packages.${pkgs.stdenv.hostPlatform.system}.default;
          host = "0.0.0.0";
          port = 23234;
          openFirewall = true;
        };
      };
  };
}
