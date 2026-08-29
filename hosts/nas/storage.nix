_: {
  systemd.services.zfs-import-main.unitConfig.RequiresMountsFor = [ "/persist" ];

  systemd.tmpfiles.rules = [
    "d /mnt/main 0755 root root -"
  ];

  fileSystems."/mnt/recovery" = {
    device = "tmpfs";
    fsType = "tmpfs";
    options = [
      "mode=0755"
      "size=2G"
    ];
  };
}
