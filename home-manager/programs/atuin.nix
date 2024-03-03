{
  config,
  pkgs,
  ...
}: let
  atuin-export-fish = pkgs.buildGoModule rec {
    pname = "atuin-export-fish-history";
    version = "0.1.0";

    src = pkgs.fetchFromGitLab {
      owner = "hmajid2301";
      repo = pname;
      rev = "v${version}";
      sha256 = "sha256-2egZYLnaekcYm2IzPdWAluAZogdi4Nf/oXWLw8+AnMk=";
    };

    vendorHash = "sha256-hLEmRq7Iw0hHEAla0Ehwk1EfmpBv6ddBuYtq12XdhVc=";

    ldflags = ["-s" "-w"];
  };
in {
  home.packages = [atuin-export-fish];

  programs.atuin = {
    enable = true;
    flags = [
      "--disable-up-arrow"
    ];
    settings = {
      sync_address = "https://majiy00-shell.fly.dev";
      sync_frequency = "15m";
      dialect = "uk";
      enter_accept = false;
      records = true;
      # key_path = config.sops.secrets.atuin_key.path;
    };
  };

  sops.secrets.atuin_key = {
    sopsFile = ../secrets.yaml;
  };
}
