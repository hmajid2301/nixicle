{
  pkgs,
  config,
  lib,
  ...
}:
with lib;
with lib.nixicle; let
  cfg = config.cli.programs.modern-unix;

  viddy = pkgs.buildGoModule rec {
    pname = "viddy";
    version = "0.4.0";

    src = pkgs.fetchFromGitHub {
      owner = "sachaos";
      repo = pname;
      rev = "v${version}";
      sha256 = "sha256-iF5b5e3HPT3GJLRDxz9wN1U5rO9Ey51Cpw4p2zjffTI=";
    };

    vendorHash = "sha256-/lx2D2FIByRnK/097M4SQKRlmqtPTvbFo1dwbThJ5Fs=";

    ldflags = ["-s" "-w"];
  };
in {
  options.cli.programs.modern-unix = with types; {
    enable = mkBoolOpt false "Whether or not to enable modern unix tools";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      viddy

      bandwhich
      broot
      choose
      curlie
      chafa
      dogdns
      duf
      delta
      du-dust
      dysk
      entr
      erdtree
      fd
      go-task
      gdu
      gping
      grex
      hyperfine
      hexyl
      jqp
      jnv
      ouch
      silver-searcher
      procs
      psensor
      tokei
      trash-cli
      tailspin
      gtrash
      ripgrep
      sd
      xcp
      yq-go

      # go
      golangci-lint
      air
      templ
      sqlc
    ];
  };
}
