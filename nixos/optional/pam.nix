{
  security.pam.services = {
    swaylock = {
      u2fAuth = true;
      fprintAuth = true;
    };

    login = {
      u2fAuth = true;
      fprintAuth = true;
    };

    sudo = {
      u2fAuth = true;
      fprintAuth = true;
    };
  };



  sops.secrets.attic_auth_token = {
    sopsFile = ../../hosts/iso/secrets.yaml;
    neededForUsers = true;
  };

  # TODO: only include if fingerprint auth
  environment.etc = {
    "acpi/laptop-lid.sh".text = ''
      #!/usr/bin/env bash

      lock=$HOME/fprint-disabled

      if grep -F closed /proc/acpi/button/lid/LID0/state
      then
      		 echo "LID CLOSED: turning off finger print"
      		 touch "$lock"
      		 systemctl stop fprintd
      		 systemctl mask fprintd
      elif [ -f "$lock" ]
      then
      		 echo "LID OPENED: turning on finger print"
      		 systemctl unmask fprintd
      		 systemctl start fprintd
      		 rm "$lock"
      fi
    '';
  };

  systemd.services.fingerprint-toggle = {
    wantedBy = [ "multi-user.target" ];
    after = [ "network-online.target" ];
    serviceConfig = {
      ExecStart = "/etc/acpi/laptop-lid.sh";
      Restart = "on-failure";
      ProtectKernelLogs = true;
      ProtectKernelModules = true;
      ProtectKernelTunables = true;
      ProtectProc = "invisible";
      ProtectSystem = "strict";
      RestrictAddressFamilies = [ "AF_INET" "AF_INET6" "AF_UNIX" ];
      RestrictNamespaces = true;
      RestrictRealtime = true;
      RestrictSUIDSGID = true;
    };
  };
}
