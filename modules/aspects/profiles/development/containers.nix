{ ... }:
{
  den.aspects.devContainers = {
    homeManager = { pkgs, ... }: {
      home.packages = with pkgs; [
        arion
        docker
        docker-compose
        dive
        amazon-ecr-credential-helper
      ];
    };
  };
}
