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

    mkdir -p $out/share/claude-code/get-shit-done

    # Copy commands
    cp -r commands/gsd $out/share/claude-code/get-shit-done/commands

    # Copy main skill
    cp -r get-shit-done $out/share/claude-code/get-shit-done/

    # Copy agents
    cp -r agents $out/share/claude-code/get-shit-done/

    # Copy hooks
    mkdir -p $out/share/claude-code/get-shit-done/hooks
    cp hooks/*.js $out/share/claude-code/get-shit-done/hooks/ 2>/dev/null || true

    # Copy documentation
    cp CHANGELOG.md $out/share/claude-code/get-shit-done/

    # Create version file
    echo "${version}" > $out/share/claude-code/get-shit-done/VERSION

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
