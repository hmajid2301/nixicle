{
  lib,
  buildGoModule,
  inputs,
}:
let
  pname = "ketch";
  version = "0.10.0";
in
buildGoModule {
  inherit pname version;

  src = inputs.ketch-src;

  vendorHash = "sha256-UsTR7+GSuxUQ0aBq8fv1M18LegeDqf/XoiyASQKe5EI=";

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
