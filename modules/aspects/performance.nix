{ den, ... }:
{
  # Tiered power profiles. Include exactly one per host.
  #
  #   den.aspects.performance-base        — servers / VMs (no power management)
  #   den.aspects.performance-balanced    — desktops (auto power-profiles-daemon)
  #   den.aspects.performance-max         — workstations / gaming (always performance)

  den.aspects = {
    performance-base = {
      nixos = _: {
        # Minimal power management — suitable for servers and VMs.
        services.power-profiles-daemon.enable = false;
        powerManagement.enable = false;
      };
    };

    performance-balanced = {
      nixos = _: {
        # Let power-profiles-daemon choose balanced/power-saver automatically.
        services.power-profiles-daemon.enable = true;
        powerManagement.enable = true;
        powerManagement.cpuFreqGovernor = "schedutil";
      };
    };

    performance-max = {
      nixos = _: {
        # Force performance governor — for gaming rigs / beefy workstations.
        services.power-profiles-daemon.enable = true;
        powerManagement.enable = true;
        powerManagement.cpuFreqGovernor = "performance";
      };
    };
  };
}
