{ ... }:
{
  den.aspects.devGo = {
    homeManager = { pkgs, ... }: {
      home.packages = with pkgs; [
        go
        goose
        golangci-lint
        air
        templ
        sqlc
        golines
        gotools
        go-task
        go-mockery
        gotestsum
        delve
      ];
    };
  };
}
