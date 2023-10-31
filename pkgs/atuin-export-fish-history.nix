{ lib
, buildGoModule
, fetchFromGitLab
}:

buildGoModule rec {
  pname = "atuin-export-fish-history";
  version = "0.1.0";

  src = fetchFromGitLab {
    owner = "hmajid2301";
    repo = pname;
    rev = "v${version}";
    sha256 = "sha256-2egZYLnaekcYm2IzPdWAluAZogdi4Nf/oXWLw8+AnMk=";
  };

  vendorHash = "sha256-hLEmRq7Iw0hHEAla0Ehwk1EfmpBv6ddBuYtq12XdhVc=";

  ldflags = [ "-s" "-w" ];
}
