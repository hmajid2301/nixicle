{
  lib,
  rustPlatform,
  fetchFromForgejo,
  ...
}:
rustPlatform.buildRustPackage {
  pname = "umami-sso";
  version = "0-unstable-2026-07-30";

  src = fetchFromForgejo {
    domain = "codeberg.org";
    owner = "vanutp";
    repo = "umami-sso";
    rev = "e3ad0bde189a6191ba297c3d868e9bf3d19d98b9";
    hash = "sha256-/8jVdCOfbZ7sx68qGi0qhqE5CbrpQHi27jdKj1edjjM=";
  };

  cargoHash = "sha256-APZoT0yKbuqQGfBCNI51wf/IobVbJBpYrVBiASTfeAo=";

  meta = {
    description = "OIDC authentication sidecar for Umami";
    homepage = "https://codeberg.org/vanutp/umami-sso";
    license = lib.licenses.mit;
    mainProgram = "sso-sidecar";
    platforms = lib.platforms.linux;
  };
}
