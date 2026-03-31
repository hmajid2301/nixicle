# hortusfox-web - Self-hostable plant collection management
#
# This is a placeholder package for NixOS/nixpkgs submission.
# The actual source is fetched from GitHub at build time.
#
# =============================================================================
# RELEASE CHECKLIST - Complete these steps before submitting to nixpkgs:
# =============================================================================
#
# 1. UPDATE VERSION
#    - Check latest release: curl -s https://api.github.com/repos/danielbrendel/hortusfox-web/releases/latest | grep tag_name
#    - Update the `version` variable below
#
# 2. GET SOURCE HASH
#    nix-prefetch-url --unpack https://github.com/danielbrendel/hortusfox-web/archive/refs/tags/vX.X.tar.gz
#    Then convert to SRI format:
#    nix hash convert --hash-algo sha256 --to sri sha256:XXXXXXXX
#
# 3. GET VENDOR HASH (for composer dependencies)
#    Temporarily comment out this entire file except the header
#    and add to your nixpkgs clone:
#    hortusfox-web = callPackage ./hortusfox-web {};
#    Then run:
#    nix-build pkgs/top-level/all-packages.nix -A hortusfox-web --check
#    The build will fail but report the correct vendorHash
#
# 4. MOVE TO NIXPKGS
#    Move this file to: pkgs/servers/web-apps/hortusfox-web/default.nix
#    Remove the `inputs` parameter (not needed in nixpkgs)
#
# 5. CREATE MODULE
#    Create: nixos/modules/services/web-apps/hortusfox-web.nix
#    See examples at:
#    - nixos/modules/services/web-apps/bentopdf.nix
#    - nixos/modules/services/web-apps/mattermost.nix
#    - nixos/modules/services/web-apps/netbox.nix
#
# 6. UPDATE TOP-LEVEL
#    Add to pkgs/top-level/all-packages.nix:
#    hortusfox-web = callPackage ../servers/web-apps/hortusfox-web { };
#
#    Add module import to nixos/modules/services/web-apps/matrix.nix (alphabetically):
#    ./hortusfox-web.nix
#
# 7. RUN TESTS
#    nix-build nixos/release.nix -A nixosTests.hortusfox-web
#
# =============================================================================

{
  lib,
  stdenv,
  fetchFromGitHub,
  php83,
  php83Extensions,
  writeTextFile,
}:

let
  pname = "hortusfox-web";
  version = "5.7"; # TODO: Update to latest release
in
stdenv.mkDerivation {
  inherit pname version;

  # TODO: Replace placeholder hash with real hash from step 2 above
  src = fetchFromGitHub {
    owner = "danielbrendel";
    repo = "hortusfox-web";
    rev = "v${version}";
    # TODO: Get this hash with: nix-prefetch-url --unpack https://github.com/danielbrendel/hortusfox-web/archive/refs/tags/v${version}.tar.gz
    sha256 = "sha256-KSmI0mGReuSZZ6Q0xP1pcluT1s6K1Y5eJvKJl8r7vW0=";
  };

  buildInputs = with php83Extensions; [
    pdo_mysql
    mbstring
    exif
    bcmath
    intl
    zip
    gd
  ];

  configurePhase = ''
    runHook preConfigurePhase
    mkdir -p storage/framework/{cache,sessions,views}
    mkdir -p storage/logs
    mkdir -p public/{img,backup,themes}
    mkdir -p bootstrap/cache
    runHook postConfigurePhase
  '';

  buildPhase = ''
    runHook preBuildPhase
    runHook postBuildPhase
  '';

  installPhase = ''
    runHook preInstallPhase
    mkdir -p $out/share/${pname}
    cp -r . $out/share/${pname}
    runHook postInstallPhase
  '';

  passthru = {
    inherit version;
    php = php83;

    phpExtensions = with php83Extensions; [
      pdo_mysql
      mbstring
      exif
      bcmath
      intl
      zip
      gd
    ];

    setupScript = writeTextFile {
      name = "setup-hortusfox.sh";
      executable = true;
      destination = "/bin/setup-hortusfox.sh";
      text = ''
        #!/usr/bin/env bash
        set -e

        cd ${placeholder "out"}/share/${pname}

        export DB_HOST=''${DB_HOST:-localhost}
        export DB_PORT=''${DB_PORT:-3306}
        export DB_DATABASE=''${DB_DATABASE:-hortusfox}
        export DB_USERNAME=''${DB_USERNAME:-hortusfox}
        export DB_PASSWORD=''${DB_PASSWORD:-}
        export APP_URL=''${APP_URL:-http://localhost:8080}

        if [ -n "''${DB_PASSWORD_FILE:-}" ]; then
          export DB_PASSWORD=$(cat "$DB_PASSWORD_FILE")
        fi

        if [ -n "''${ADMIN_PASSWORD_FILE:-}" ]; then
          export ADMIN_PASSWORD=$(cat "$ADMIN_PASSWORD_FILE")
        fi

        php asatru key:generate || true
        php asatru migrate --force || true

        if [ -n "''${ADMIN_EMAIL:-}" ] && [ -n "''${ADMIN_PASSWORD:-}" ]; then
          php asatru user:create "''${ADMIN_EMAIL}" "''${ADMIN_PASSWORD}" || true
        fi

        echo "HortusFox Web setup complete"
      '';
    };
  };

  meta = with lib; {
    homepage = "https://github.com/danielbrendel/hortusfox-web";
    description = "Self-hostable plant collection management system";
    changelog = "https://github.com/danielbrendel/hortusfox-web/blob/main/CHANGELOG.md";
    license = licenses.agpl3Only;
    maintainers = with maintainers; [ ];
    platforms = platforms.linux;
  };
}
