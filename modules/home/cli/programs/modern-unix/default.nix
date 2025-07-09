{
  pkgs,
  config,
  lib,
  ...
}:
with lib;
with lib.nixicle;
let
  cfg = config.cli.programs.modern-unix;
in
{
  options.cli.programs.modern-unix = with types; {
    enable = mkBoolOpt false "Whether or not to enable modern unix tools";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      broot
      choose
      curlie
      chafa
      dogdns
      doggo
      duf
      delta
      du-dust
      dysk
      entr
      erdtree
      fd
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
      tokei
      gomi
      tailspin
      ripgrep
      sd
      xcp
      yq-go
      viddy

      kaf

      # go
      go
      goose
      golangci-lint
      air
      templ
      sqlc
      golines
      gotools
      go-task
      go-mockery
      gotestsum

      nodejs_24

      sshx
    ];
  };
}
