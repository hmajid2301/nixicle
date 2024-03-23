{
  pkgs,
  config,
  lib,
  ...
}:
with lib;
with lib.nixicle; let
  cfg = config.cli.programs.modern-unix;
in {
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
      duf
      delta
      du-dust
      dysk
      entr
      erdtree
      fd
      gdu
      gping
      hyperfine
      hexyl
      ouch
      silver-searcher
      procs
      psensor
      trash-cli
      gtrash
      ripgrep
      sd
      xcp
      yq-go
    ];
  };
}
