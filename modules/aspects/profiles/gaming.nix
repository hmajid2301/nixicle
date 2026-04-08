{ den, ... }:
{
  den.aspects.gaming = {
    nixos = { pkgs, ... }: {
      hardware.graphics = {
        enable = true;
        extraPackages = with pkgs; [
          mesa
          libva
          libvdpau-va-gl
          vulkan-loader
          vulkan-validation-layers
          mesa.opencl
          rocmPackages.clr.icd
        ];
      };

      services.ratbagd.enable = true;

      programs = {
        gamemode.enable = true;
        gamescope.enable = true;
        steam = {
          enable = true;
          package = pkgs.steam.override {
            extraPkgs = p: with p; [
              mangohud
              gamemode
            ];
          };
          dedicatedServer.openFirewall = true;
          remotePlay.openFirewall = true;
          gamescopeSession.enable = true;
          extraCompatPackages = with pkgs; [ proton-ge-bin ];
        };
      };

      services.xserver.videoDrivers = [ "amdgpu" ];
      environment.variables = {
        RUSTICL_ENABLE = "radeonsi";
        ROC_ENABLE_PRE_VEGA = "1";
      };

      environment.systemPackages = with pkgs; [
        winetricks
        wineWow64Packages.waylandFull
        adwsteamgtk
        mesa-demos
        vulkan-tools
        clinfo
        ffmpeg
      ];
    };

    homeManager = { pkgs, ... }: {
      programs.mangohud = {
        enable = false;
        enableSessionWide = true;
        settings.cpu_load_change = true;
      };
      home.packages = with pkgs; [
        lutris
        bottles
      ];
    };
  };
}
