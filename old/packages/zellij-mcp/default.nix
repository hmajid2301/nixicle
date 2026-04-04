{
  lib,
  stdenv,
  nodejs,
  makeWrapper,
  inputs,
}:

stdenv.mkDerivation {
  pname = "zellij-mcp-server";
  version = "0.1.0";

  src = inputs.zellij-mcp;

  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin $out/lib/zellij-mcp-server

    cp -r dist $out/lib/zellij-mcp-server/
    cp -r node_modules $out/lib/zellij-mcp-server/
    cp package.json $out/lib/zellij-mcp-server/

    makeWrapper ${nodejs}/bin/node $out/bin/zellij-mcp \
      --add-flags "$out/lib/zellij-mcp-server/dist/index.js"

    runHook postInstall
  '';

  nativeBuildInputs = [ makeWrapper ];

  meta = with lib; {
    description = "A comprehensive Model Context Protocol (MCP) server for managing Zellij terminal workspace sessions";
    homepage = "https://github.com/GitJuhb/zellij-mcp-server";
    license = licenses.mit;
  };
}
