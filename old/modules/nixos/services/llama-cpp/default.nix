{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.services.nixicle.llama-cpp;

  llama-cpp-vulkan = pkgs.llama-cpp.override {
    vulkanSupport = true;
  };
in
{
  options.services.nixicle.llama-cpp = {
    enable = mkEnableOption "Enable llama.cpp with Vulkan support";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ llama-cpp-vulkan ];

    hardware.graphics = {
      enable = true;
      enable32Bit = true;
    };

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
          ${llama-cpp-vulkan}/bin/llama-server \
            --host 0.0.0.0 \
            --port 11435 \
            --n-gpu-layers 999
        '';

        Restart = "on-failure";
        RestartSec = "5s";

        SupplementaryGroups = [ "video" "render" ];
      };
    };

    environment.persistence = mkIf config.system.impermanence.enable {
      "/persist" = {
        directories = [
          "/var/lib/private/llama-cpp"
        ];
      };
    };
  };
}
