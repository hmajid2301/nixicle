{
  symlinkJoin,
  fetchFromGitHub,
  writeScriptBin,
  writeTextFile,
  makeWrapper,
  python311,
  snapraid,
  snapraid-btrfs,
  snapper,
}: let
  name = "snapraid-btrfs-runner";
  deps = [python311 config snapraid snapraid-btrfs snapper];
  src = fetchFromGitHub {
    owner = "fmoledina";
    repo = "snapraid-btrfs-runner";
    rev = "afb83c67c61fdf3769aab95dba6385184066e119";
    sha256 = "M8LXxsc7jEn5GsiXAKykmFUgsij2aOIenw1Dx+/5Rww=";
  };
  config = writeTextFile {
    name = "snapraid-btrfs-runner.conf";
    text = ''
      [snapraid-btrfs]
      ; path to the snapraid-btrfs executable (e.g. /usr/bin/snapraid-btrfs)
      executable = ${snapraid-btrfs}/bin/snapraid-btrfs
      ; optional: specify snapper-configs and/or snapper-configs-file as specified in snapraid-btrfs
      ; only one instance of each can be specified in this config
      snapper-configs =
      snapper-configs-file =
      ; specify whether snapraid-btrfs should run the pool command after the sync, and optionally specify pool-dir
      pool = false
      pool-dir =
      ; specify whether snapraid-btrfs-runner should automatically clean up all but the last snapraid-btrfs sync snapshot after a successful sync
      cleanup = true

      [snapper]
      ; path to snapper executable (e.g. /usr/bin/snapper)
      executable = ${snapper}/bin/snapper

      [snapraid]
      ; path to the snapraid executable (e.g. /usr/bin/snapraid)
      executable = ${snapraid}/bin/snapraid
      ; path to the snapraid config to be used
      config = /etc/snapraid.conf
      ; abort operation if there are more deletes than this, set to -1 to disable
      deletethreshold = 40
      ; if you want touch to be ran each time
      touch = false

      [logging]
      ; logfile to write to, leave empty to disable
      file =
      ; maximum logfile size in KiB, leave empty for infinite
      maxsize = 5000

      [email]
      ; when to send an email, comma-separated list of [success, error]
      sendon =
      ; set to false to get full programm output via email
      short = false
      subject = [SnapRAID] Status Report:
      from =
      to =
      ; maximum email size in KiB
      maxsize = 500

      [smtp]
      host = somesmtphost
      ; leave empty for default port
      port = 587
      ; set to "true" to activate
      ssl = false
      tls = true
      user = someuser
      password = somepassword

      [scrub]
      ; set to true to run scrub after sync
      enabled = false
      ; plan can be 0-100 percent, new, bad, or full
      plan = 12
      ; only used for percent scrub plan
      older-than = 10
    '';
    destination = "/etc/${name}";
  };
  script =
    (
      writeScriptBin name
      (builtins.readFile (src + "/snapraid-btrfs-runner.py"))
    )
    .overrideAttrs (old: {
      buildCommand = "${old.buildCommand}\n patchShebangs $out";
    });
in
  symlinkJoin {
    inherit name;
    paths = [script] ++ deps;
    buildInputs = [makeWrapper python311];
    postBuild = "wrapProgram $out/bin/${name} --add-flags '-c ${config}/etc/snapraid-btrfs-runner' --set PATH $out/bin";
  }
