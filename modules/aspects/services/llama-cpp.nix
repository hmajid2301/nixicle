{ den, ... }:
{
  den.aspects.llama-cpp = {
    nixos = { config, pkgs, lib, ... }: {
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
          SupplementaryGroups = [ "video" "render" ];
        };
      };

      environment.persistence."/persist".directories =
        lib.mkIf config.system.impermanence.enable [ "/var/lib/private/llama-cpp" ];
    };
  };
}
