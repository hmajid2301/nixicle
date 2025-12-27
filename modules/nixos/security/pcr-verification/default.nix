{
  config,
  lib,
  utils,
  ...
}:
with lib;
with lib.nixicle;
let
  cfg = config.security.nixicle.pcr-verification;
in
{
  options.security.nixicle.pcr-verification = with types; {
    enable = mkEnableOption "Enable TPM2 PCR 15 verification for LUKS volumes";

    expectedPcr15 = mkOption {
      type = nullOr str;
      default = null;
      description = ''
        The expected value of PCR 15 after all LUKS partitions have been unlocked.
        Should be a 64 character hex string as output by the sha256 field of
        'systemd-analyze pcrs 15 --json=short'

        If set to null (the default) it will not check the value.
        If the check fails the boot will abort and you will be dropped into an emergency shell.

        In emergency shell type:
        'systemctl disable check-pcrs'
        'systemctl default'
        to continue booting
      '';
      example = "6214de8c3d861c4b451acc8c4e24294c95d55bcec516bbf15c077ca3bffb6547";
    };
  };

  options.boot.initrd.luks.devices = lib.mkOption {
    type =
      with types;
      attrsOf (submodule {
        config.crypttabExtraOpts = optionals cfg.enable [
          "tpm2-device=auto"
          "tpm2-measure-pcr=yes"
        ];
      });
  };

  config = mkIf cfg.enable {
    boot.kernelParams = [ "rd.luks=no" ];

    boot.initrd.systemd.services = {
      check-pcrs = mkIf (cfg.expectedPcr15 != null) {
        script = ''
          echo "Checking PCR 15 value"
          if [[ $(systemd-analyze pcrs 15 --json=short | jq -r ".[0].sha256") != "${cfg.expectedPcr15}" ]] ; then
            echo "PCR 15 check failed"
            exit 1
          else
            echo "PCR 15 check succeeded"
          fi
        '';
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };
        unitConfig.DefaultDependencies = "no";
        after = [ "cryptsetup.target" ];
        before = [ "sysroot.mount" ];
        requiredBy = [ "sysroot.mount" ];
      };
    }
    // (listToAttrs (
      foldl' (
        acc: attrs:
        let
          extraOpts = attrs.value.crypttabExtraOpts ++ (optional attrs.value.allowDiscards "discard");
          cfg' = config.boot.initrd.systemd;
        in
        [
          (nameValuePair "cryptsetup-${attrs.name}" {
            unitConfig = {
              Description = "Cryptography setup for ${attrs.name}";
              DefaultDependencies = "no";
              IgnoreOnIsolate = true;
              Conflicts = [ "umount.target" ];
              BindsTo = "${utils.escapeSystemdPath attrs.value.device}.device";
            };
            serviceConfig = {
              Type = "oneshot";
              RemainAfterExit = true;
              TimeoutSec = "infinity";
              KeyringMode = "shared";
              OOMScoreAdjust = 500;
              ImportCredential = "cryptsetup.*";
              ExecStart = ''${cfg'.package}/bin/systemd-cryptsetup attach '${attrs.name}' '${attrs.value.device}' '-' '${concatStringsSep "," extraOpts}' '';
              ExecStop = ''${cfg'.package}/bin/systemd-cryptsetup detach '${attrs.name}' '';
            };
            after = [
              "cryptsetup-pre.target"
              "systemd-udevd-kernel.socket"
              "${utils.escapeSystemdPath attrs.value.device}.device"
            ]
            ++ (optional cfg'.tpm2.enable "systemd-tpm2-setup-early.service")
            ++ optional (acc != [ ]) "${(head acc).name}.service";
            before = [
              "blockdev@dev-mapper-${attrs.name}.target"
              "cryptsetup.target"
              "umount.target"
            ];
            wants = [ "blockdev@dev-mapper-${attrs.name}.target" ];
            requiredBy = [ "sysroot.mount" ];
          })
        ]
        ++ acc
      ) [ ] (sortOn (x: x.name) (lib.attrsets.attrsToList config.boot.initrd.luks.devices))
    ));
  };
}
