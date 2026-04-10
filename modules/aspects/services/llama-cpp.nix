{ den, lib, ... }:
{
  den.aspects.llama-cpp = {
    includes = [ (import ./_persist-forwarder.nix { inherit den lib; }) ];
    persist.directories = [ "/var/lib/private/llama-cpp" ];
    nixos =
      {
        pkgs,
        ...
      }:
      {
        hardware.graphics = {
          enable = true;
          enable32Bit = true;
        };

        environment.systemPackages = [
          (pkgs.llama-cpp.override { vulkanSupport = true; })
        ];

        systemd.services.llama-cpp = {
          description = "llama.cpp HTTP server with Vulkan acceleration";
          wantedBy = [ "multi-user.target" ];
          after = [ "network.target" ];
          serviceConfig = {
            Type = "simple";
            User = "llama-cpp";
            Group = "llama-cpp";
            DynamicUser = true;
            StateDirectory = "llama-cpp";
            ExecStart = ''
              ${pkgs.llama-cpp.override { vulkanSupport = true; }}/bin/llama-server \
                --host 0.0.0.0 \
                --port 11435 \
                --n-gpu-layers 999
            '';
            Restart = "on-failure";
            RestartSec = "5s";
            SupplementaryGroups = [
              "video"
              "render"
            ];
          };
        };

      };
  };
}
