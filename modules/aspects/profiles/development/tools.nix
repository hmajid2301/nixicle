_: {
  den.aspects.devTools = {
    homeManager =
      { pkgs, lib, ... }:
      let
        atuin-export-fish = pkgs.buildGoModule rec {
          pname = "atuin-export-fish-history";
          version = "unstable-2026-07-07";
          src = pkgs.fetchFromGitLab {
            owner = "hmajid2301";
            repo = pname;
            rev = "def956c";
            hash = "sha256-ZQLOfLJSBIu/GyDH1AYM/+m0CTw9RXw1U/SR6Vrl4pk=";
          };
          vendorHash = "sha256-hLEmRq7Iw0hHEAla0Ehwk1EfmpBv6ddBuYtq12XdhVc=";
          ldflags = [
            "-s"
            "-w"
          ];
        };
      in
      {
        home.packages = [
          atuin-export-fish
          pkgs.nixicle.glci
        ]
        ++ (with pkgs; [
          gh-dash
          gum
          broot
          erdtree
          fd
          xcp
          entr
          choose
          ripgrep
          sd
          grex
          yq-go
          jq
          duf
          dust
          dysk
          gdu
          procs
          gping
          viddy
          hexyl
          delta
          chafa
          ouch
          jqp
          jnv
          curlie
          doggo
          hyperfine
          tokei
          gomi
          tailspin
          sshx
          glow
          (lib.hiPrio parallel)
          moreutils
          unzip
          gnupg
          optinix
          gcx
          gnumake
          imagemagick
          ffmpegthumbnailer
          fontpreview
          unar
          poppler
        ]);
      };
  };
}
