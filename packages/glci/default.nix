# TODO: remove local package once glci lands in nixpkgs.
{
  lib,
  buildGoModule,
  inputs,
}:
buildGoModule rec {
  pname = "glci";
  version = "unstable";

  src = inputs.glci;

  subPackages = [ "cmd/glci" ];

  # TODO: add a CI build check for glci to catch stale vendorHash after input updates.
  vendorHash = "sha256-2YjLZjJQcmXVR3Aj9ez9kSDTE4I85hc88TzxmsfFzfE=";

  ldflags = [
    "-s"
    "-w"
  ];

  # TODO: re-enable checks once upstream tests stop assuming a writable $HOME.
  doCheck = false;

  meta = with lib; {
    description = "Run GitLab CI/CD pipelines locally";
    homepage = "https://gitlab.com/gitlab-org/ci-cd/runner-tools/glci";
    license = licenses.mit;
    mainProgram = "glci";
    platforms = platforms.linux ++ platforms.darwin;
    maintainers = with maintainers; [ ];
  };
}
