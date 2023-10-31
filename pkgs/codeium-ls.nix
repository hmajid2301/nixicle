{ stdenv
, fetchurl
, autoPatchelfHook
,
}:
stdenv.mkDerivation {
  name = "codeium";
  src = fetchurl {
    url = "https://github.com/Exafunction/codeium/releases/download/language-server-v1.4.5/language_server_linux_x64";
    sha256 = "sha256-zLfhEq6/0T4pj4WIj10bFN2mRcpMXRu7lgtjZ62P4nM=";
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
