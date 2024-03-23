{
  lib,
  pkgs,
  config,
  ...
}:
with lib;
with lib.nixicle; let
  inherit (lib) types mkOption mkEnableOption optional optionals;
  cfg = config.services.virtualisation.vfio;

  tmpfileEntry = name: f: "f /dev/shm/${name} ${f.mode} ${f.user} ${f.group} -";

  boolToZeroOne = x:
    if x
    then "1"
    else "0";

  aclString = with lib.strings;
    concatMapStringsSep ''
      ,
    ''
    escapeNixString
    config.services.virtualisation.vfio.libvirtd.deviceACL;
in {
  # Based on this https://gist.github.com/CRTified/43b7ce84cd238673f7f24652c85980b3
  options.services.virtualisation.vfio = {
    enable = mkEnableOption "enable kvm vfio virtualisation";

    libvirtd = {
      deviceACL = mkOption {
        type = types.listOf types.str;
        default = [];
      };
      clearEmulationCapabilities = mkOption {
        type = types.bool;
        default = true;
      };
    };

    IOMMUType = mkOption {
      type = types.enum ["intel" "amd"];
      example = "intel";
      description = "Type of the IOMMU used";
    };
    devices = mkOption {
      type = types.listOf (types.strMatching "[0-9a-f]{4}:[0-9a-f]{4}");
      default = [];
      example = ["10de:1b80" "10de:10f0"];
      description = "PCI IDs of devices to bind to vfio-pci";
    };
    disableEFIfb = mkOption {
      type = types.bool;
      default = false;
      example = true;
      description = "Disables the usage of the EFI framebuffer on boot.";
    };
    blacklistNvidia = mkOption {
      type = types.bool;
      default = false;
      description = "Add Nvidia GPU modules to blacklist";
    };
    ignoreMSRs = mkOption {
      type = types.bool;
      default = false;
      example = true;
      description = "Enables or disables kvm guest access to model-specific registers";
    };
    sharedMemoryFiles = mkOption {
      type = types.attrsOf (types.submodule ({name, ...}: {
        options = {
          name = mkOption {
            visible = false;
            default = name;
            type = types.str;
          };
          user = mkOption {
            type = types.str;
            default = "root";
            description = "Owner of the memory file";
          };
          group = mkOption {
            type = types.str;
            default = "root";
            description = "Group of the memory file";
          };
          mode = mkOption {
            type = types.str;
            default = "0600";
            description = "Group of the memory file";
          };
        };
      }));
      default = {};
    };
    hugepages = {
      enable = mkEnableOption "Hugepages";

      defaultPageSize = mkOption {
        type = types.strMatching "[0-9]*[kKmMgG]";
        default = "1M";
        description = "Default size of huge pages. You can use suffixes K, M, and G to specify KB, MB, and GB.";
      };
      pageSize = mkOption {
        type = types.strMatching "[0-9]*[kKmMgG]";
        default = "1M";
        description = "Size of huge pages that are allocated at boot. You can use suffixes K, M, and G to specify KB, MB, and GB.";
      };
      numPages = mkOption {
        type = types.ints.positive;
        default = 1;
        description = "Number of huge pages to allocate at boot.";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    services.virtualisation.kvm.enable = true;

    boot = {
      kernelParams =
        (
          if cfg.IOMMUType == "intel"
          then [
            "intel_iommu=on"
            "intel_iommu=igfx_off"
          ]
          else ["amd_iommu=on"]
        )
        ++ (optional (builtins.length cfg.devices > 0)
          ("vfio-pci.ids=" + builtins.concatStringsSep "," cfg.devices))
        ++ (optional cfg.disableEFIfb "video=efifb:off")
        ++ (optionals cfg.ignoreMSRs [
          "kvm.ignore_msrs=1"
          "kvm.report_ignored_msrs=0"
        ])
        ++ optionals cfg.hugepages.enable [
          "default_hugepagesz=${cfg.hugepages.defaultPageSize}"
          "hugepagesz=${cfg.hugepages.pageSize}"
          "hugepages=${toString cfg.hugepages.numPages}"
        ];

      kernelModules = ["vfio_pci" "vfio_iommu_type1" "vfio"];

      initrd.kernelModules = ["vfio_pci" "vfio_iommu_type1" "vfio"];
      blacklistedKernelModules =
        optionals cfg.blacklistNvidia ["nvidia" "nouveau"];
    };

    # Add qemu-libvirtd to the input group if required
    users.users."qemu-libvirtd" = {
      extraGroups = optionals (!cfg.qemu.runAsRoot) ["kvm" "input"];
      isSystemUser = true;
    };

    environment.systemPackages = with pkgs; [
      virtiofsd
      looking-glass-client
    ];

    virtualisation.libvirtd.qemu.verbatimConfig = ''
      clear_emulation_capabilities = ${
        boolToZeroOne cfg.libvirtd.clearEmulationCapabilities
      }
      cgroup_device_acl = [
        ${aclString}
      ]
    '';

    services.udev.extraRules = ''
      SUBSYSTEM=="vfio", OWNER="root", GROUP="kvm"
    '';

    systemd.tmpfiles.rules =
      mapAttrsToList tmpfileEntry cfg.sharedMemoryFiles;
  };
}
