{
  symlinkJoin,
  fetchFromGitHub,
  writeScriptBin,
  makeWrapper,
  coreutils,
  gnugrep,
  gawk,
  gnused,
  snapraid,
  snapper,
}: let
  name = "snapraid-btrfs";
  deps = [coreutils gnugrep gawk gnused snapraid snapper];
  script =
    (
      writeScriptBin name
      # NOTE: Forked version from D34DC3N73R to fix snapper 0.11.1 compatibility
      (builtins.readFile ((fetchFromGitHub {
          owner = "D34DC3N73R";
          repo = "snapraid-btrfs";
          rev = "ea9a1cfbfbe1cefcae9c038e1a4962d4bc2de843";
          sha256 = "sha256-+UCBGlGFqRKgFjCt1GdOSxaayTONfwisxdnZEwxOnSY=";
        })
        + "/snapraid-btrfs"))
    )
    .overrideAttrs (old: {
      buildCommand = "${old.buildCommand}\n patchShebangs $out";
    });
in
  symlinkJoin {
    inherit name;
    paths = [script] ++ deps;
    buildInputs = [makeWrapper];
    postBuild = "wrapProgram $out/bin/${name} --set PATH $out/bin";
  }
