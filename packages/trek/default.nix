# TREK - Collaborative trip planning application
#
# Self-hosted travel planning app with real-time collaboration, maps, and budgets.
# Built with Node.js + Express + React + SQLite.
#
# =============================================================================
# NATIVE PACKAGING STATUS:
# =============================================================================
#
# Native packaging is complex due to:
# 1. TREK is a monorepo with separate client/server directories
# 2. The client uses 'sharp' which requires native compilation
# 3. Nix's sandboxed build environment blocks network access (npm ci fails)
# 4. npm has known issues in Nix build environments
#
# For nixpkgs submission, consider these approaches:
# 1. Use pre-built client dist copied from Docker image
# 2. Use node2nix with offline package.json
# 3. Create separate packages for client and server
# 4. Vendor node_modules
#
# Current status: Container-based (see modules/nixos/services/trek/default.nix)
#
# =============================================================================

{
  lib,
  stdenv,
  fetchFromGitHub,
  nodejs_22,
}:
let
  pname = "trek";
  version = "2.7.1";
in
stdenv.mkDerivation {
  inherit pname version;

  src = fetchFromGitHub {
    owner = "mauriceboe";
    repo = "TREK";
    rev = "v${version}";
    hash = "sha256-Iss6s47aKBQbGdoj1JvbMbc8Y4+hes/64Z2b+mMXkeo=";
  };

  # Note: This is a placeholder. Native build requires solving:
  # - Monorepo structure (client + server)
  # - Sharp native compilation
  # - Network access in sandbox

  buildPhase = ''
    runHook preBuildPhase
    # TODO: Native build implementation needed
    echo "Native packaging not yet implemented - using container"
    runHook postBuildPhase
  '';

  installPhase = ''
    runHook preInstallPhase
    mkdir -p $out/share/${pname}
    echo "See container-based deployment in modules/nixos/services/trek/default.nix"
    runHook postInstallPhase
  '';

  meta = with lib; {
    homepage = "https://github.com/mauriceboe/TREK";
    description = "Collaborative trip planning application";
    changelog = "https://github.com/mauriceboe/TREK/releases";
    license = licenses.agpl3Only;
    maintainers = with maintainers; [ ];
    platforms = platforms.linux;
    mainProgram = pname;
  };
}
