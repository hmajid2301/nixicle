{ stdenv
, fetchurl
, unzip
, bash
, nodePackages
, which
,
}:
stdenv.mkDerivation {
  pname = "catppuccin-lemmy";
  version = "1.0.0";

  srcs = [
    (fetchurl {
      url = "https://github.com/twbs/bootstrap/archive/refs/tags/v4.6.2.zip";
      sha256 = "sha256-HJC40r3vrb7c8bjy4Wu+iHCdWtwShuRBcX8KAJPwVIY=";
    })
    ../.
  ];

  nativeBuildInputs = [ unzip nodePackages.sass bash which ];

  unpackPhase = ''
    runHook preUnpack

    sources=($srcs)

    mkdir catppuccin-lemmy
    mkdir bootstrap

    cp -r ''${sources[1]}/. catppuccin-lemmy

    ls catppuccin-lemmy

    mkdir -p catppuccin-lemmy/node_modules/bootstrap

    unzip ''${sources[0]} 'bootstrap-4.6.2/scss*' -d bootstrap
    mv bootstrap/bootstrap-4.6.2/scss catppuccin-lemmy/node_modules/bootstrap

    patchShebangs catppuccin-lemmy/build.sh
  '';

  buildPhase = ''
    cd catppuccin-lemmy

    ./build.sh
  '';

  installPhase = ''
    mkdir -p $out

    cp dist/* $out
  '';
}
