{ lib, buildGoPackage, fetchFromGitHub, tetex, makeWrapper, ... }:

with lib;

buildGoPackage {
  pname = "gocover-cobertura";
  rev = "6cd052f49eea7ddd3e15ba416b204ff72e2772e0";

  goPackagePath = "github.com/boumenot/gocover-cobertura";

  nativeBuildInputs = [ makeWrapper ];

  src = fetchFromGitHub {
    inherit rev;
    owner = "boumenot";
    repo = "gocover-cobertura";
    sha256 = "sha256-lsraJwx56I2Gn8CePWUlQu1qdMp78P4xwPzLxetYUcw=";
  };

  meta = {
    description = "This is a simple helper tool for generating XML output in Cobertura format for CIs like Jenkins and others from go tool cover output.";
    homepage = "https://github.com/boumenot/gocover-cobertura";
    license = licenses.mit;
  };
}
