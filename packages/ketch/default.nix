{
  lib,
  buildGoModule,
  inputs,
}:
let
  pname = "ketch";
  version = "0.9.0";
in
buildGoModule {
  inherit pname version;

  src = inputs.ketch-src;

  vendorHash = "sha256-m3IwAYsczsxcVk9fay+f2AsNjmXoPk7NS0abES6b594=";

  ldflags = [
    "-s"
    "-w"
  ];

  meta = with lib; {
    description = "Fast, stateless CLI for web search, code search, library docs, and scraping";
    homepage = "https://github.com/1broseidon/ketch";
    changelog = "https://github.com/1broseidon/ketch/releases/tag/v${version}";
    license = licenses.mit;
    mainProgram = pname;
    platforms = platforms.linux ++ platforms.darwin;
  };
}
