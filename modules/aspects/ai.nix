{ den, ... }:
{
  flake-file.inputs.get-shit-done = {
    url = "github:gsd-build/get-shit-done/v1.21.1";
    flake = false;
  };
  flake-file.inputs.zellij-mcp = {
    url = "github:GitJuhb/zellij-mcp-server";
    flake = false;
  };

  den.aspects.ai = { };
}
