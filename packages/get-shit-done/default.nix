{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
  nodejs,
}:
stdenvNoCC.mkDerivation rec {
  pname = "get-shit-done";
  version = "0.1.0";

  src = fetchFromGitHub {
    owner = "gsd-build";
    repo = "get-shit-done";
    rev = "main";
    hash = "sha256-m0kRPIP5XnoeAnIEj6TZ85C8pw36Y/zLEbnX9dyjAd4=";
  };

  nativeBuildInputs = [ nodejs ];

  installPhase = ''
    runHook preInstall

    # Set up temporary home directory for install script
    export HOME=$TMPDIR
    mkdir -p $HOME/.config/opencode
    mkdir -p $HOME/.claude

    mkdir -p $out/share/claude-code
    mkdir -p $out/share/opencode

    # Run install.js for Claude Code
    node bin/install.js --claude --global --config-dir $out/share/claude-code

    # Run install.js for OpenCode
    node bin/install.js --opencode --global --config-dir $out/share/opencode

    runHook postInstall
  '';

  meta = with lib; {
    description = "Meta-prompting and context engineering system for Claude Code";
    homepage = "https://github.com/gsd-build/get-shit-done";
    license = licenses.mit;
    maintainers = [ ];
    platforms = platforms.all;
  };
}
