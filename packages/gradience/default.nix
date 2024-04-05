{
  pkgs,
  lib,
  fetchFromGitHub,
  ...
}:
pkgs.python3Packages.buildPythonApplication {
  pname = "gradience";
  version = "0.8.0-beta1";

  src = fetchFromGitHub {
    owner = "GradienceTeam";
    repo = "Gradience";
    rev = "90b774174da0e3c6b5314e38226bea653a5bf57a";
    sha256 = "sha256-C0GV6vOEZ0wTaKO7BgGuFvHsHeaVwH0W1U8yKUMrO9c=";
    fetchSubmodules = true;
  };

  format = "other";
  dontWrapGApps = true;

  nativeBuildInputs = with pkgs; [
    git
    appstream-glib
    blueprint-compiler
    desktop-file-utils
    gettext
    glib
    gobject-introspection
    meson
    ninja
    pkg-config
    wrapGAppsHook4
    sassc
  ];

  buildInputs = with pkgs; [
    glib-networking
    libadwaita
    libportal
    libportal-gtk4
    librsvg
    libsoup_3
  ];

  propagatedBuildInputs = with pkgs.python3Packages; [
    anyascii
    jinja2
    lxml
    material-color-utilities
    pygobject3
    svglib
    yapsy
    libsass
  ];

  preFixup = ''
    makeWrapperArgs+=("''${gappsWrapperArgs[@]}")
  '';

  meta = with lib; {
    homepage = "https://github.com/GradienceTeam/Gradience";
    description = "Customize libadwaita and GTK3 apps (with adw-gtk3)";
    license = licenses.gpl3Plus;
    maintainers = with maintainers; [foo-dogsquared];
  };
}
