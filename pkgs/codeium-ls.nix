{ stdenv
, fetchurl
, autoPatchelfHook
,
}:
stdenv.mkDerivation {
  name = "codeium";
  src = fetchurl {
    url = "https://github.com/Exafunction/codeium/releases/download/language-server-v1.2.99/language_server_linux_x64";
    sha256 = "sha256-AF04IXag1tF/gaU2aVOC1VdFpOpNeba1oJy0gMo9wKk=";
  };
  nativeBuildInputs = [ autoPatchelfHook ];
  unpackPhase = "true";
  installPhase = ''
    ls -lR $src
    mkdir -p $out/bin
    cp $src $out/bin/language_server_linux_x64
    chmod +x $out/bin/language_server_linux_x64
  '';
}
