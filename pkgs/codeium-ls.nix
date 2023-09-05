{ stdenv
, fetchurl
, autoPatchelfHook
,
}:
stdenv.mkDerivation {
  name = "codeium";
  src = fetchurl {
    url = "https://github.com/Exafunction/codeium/releases/download/language-server-v1.2.76/language_server_linux_x64";
    sha256 = "sha256-q9FqfElQMTMzWod7YwcpbZNUz/dy1o5QgmzvIfrAPAo=";
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
