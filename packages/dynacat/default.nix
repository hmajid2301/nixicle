# TODO: remove once upstream package lands in nixpkgs.
# Package: https://github.com/NixOS/nixpkgs/pull/562771
# Module (services.dynacat): https://github.com/NixOS/nixpkgs/pull/564403
{
  lib,
  buildGoModule,
  fetchFromGitHub,
  ...
}:
buildGoModule rec {
  pname = "dynacat";
  version = "3.0.0";

  src = fetchFromGitHub {
    owner = "Panonim";
    repo = "dynacat";
    tag = version;
    hash = "sha256-rsZTIEXxyLYYqyoy8NGUN6jOWTx1WPDyom56D1mevbI=";
  };

  vendorHash = "sha256-mpEeOPYhqJABNxheSHYWngyYJQJJTqtiW7dlm+O4LpI=";

  postPatch = ''
    substituteInPlace internal/dynacat/widget-torrenting.go \
      --replace-fail 'if strings.TrimSpace(string(body)) != "Ok." {' 'if resp.StatusCode != http.StatusNoContent && strings.TrimSpace(string(body)) != "Ok." {'
  '';

  ldflags = [
    "-s"
    "-w"
    "-X github.com/Panonim/dynacat/internal/dynacat.buildVersion=${version}"
  ];

  meta = with lib; {
    description = "Self-hosted dashboard focused on dynamic updates and integrations, forked from Glance";
    homepage = "https://github.com/Panonim/dynacat";
    license = licenses.agpl3Only;
    mainProgram = "dynacat";
    platforms = platforms.linux ++ platforms.darwin;
  };
}
