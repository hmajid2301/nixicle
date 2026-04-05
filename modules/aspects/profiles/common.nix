{ den, ... }:
let
  sharedNixConfig = import ../../../old/modules/shared/nix-caches.nix;
in
{
  den.aspects.common = {
    includes = [ den.aspects.stylix den.aspects.boot ];

    nixos = { pkgs, lib, inputs, options, ... }: {
      # Networking
      networking.firewall.enable = true;
      networking.networkmanager = {
        enable = true;
        settings.main.no-auto-default = "*";
      };
      systemd.services.NetworkManager-wait-online.enable = false;

      # SSH
      services.openssh = {
        enable = true;
        ports = [ 22 ];
        settings = {
          PasswordAuthentication = false;
          PermitRootLogin = "prohibit-password";
          StreamLocalBindUnlink = "yes";
          GatewayPorts = "clientspecified";
          KexAlgorithms = [
            "sntrup761x25519-sha512@openssh.com"
            "curve25519-sha256"
            "curve25519-sha256@libssh.org"
          ];
          Ciphers = [
            "chacha20-poly1305@openssh.com"
            "aes256-gcm@openssh.com"
            "aes128-gcm@openssh.com"
          ];
          Macs = [
            "hmac-sha2-512-etm@openssh.com"
            "hmac-sha2-256-etm@openssh.com"
          ];
        };
      };

      # Sops (age key via SSH host key)
      sops.age.sshKeyPaths = [ "/persist/etc/ssh/ssh_host_ed25519_key" ];

      # YubiKey
      services = {
        pcscd.enable = true;
        udev.packages = with pkgs; [ yubikey-personalization ];
        dbus.packages = [ pkgs.gcr ];
        udev.extraRules = ''
          ACTION=="remove",\
           ENV{ID_BUS}=="usb",\
           ENV{ID_MODEL_ID}=="0407",\
           ENV{ID_VENDOR_ID}=="1050",\
           ENV{ID_VENDOR}=="Yubico",\
           RUN+="${pkgs.systemd}/bin/loginctl lock-sessions"
        '';
      };
      security.pam.services = {
        swaylock.u2fAuth = true;
        hyprlock.u2fAuth = true;
        login.u2fAuth = true;
        sudo.u2fAuth = true;
      };

      # Nix settings
      nix = {
        channel.enable = false;
        nixPath = [ "nixpkgs=flake:nixpkgs" ];
        settings = {
          trusted-users = [ "@wheel" "root" ];
          auto-optimise-store = lib.mkDefault true;
          system-features = [ "kvm" "big-parallel" "nixos-test" ];
          flake-registry = "";
          require-sigs = true;
          fallback = true;
        } // sharedNixConfig;
        registry.nixpkgs.flake = inputs.nixpkgs;
        gc = {
          automatic = lib.mkDefault true;
          dates = lib.mkDefault "weekly";
          options = lib.mkDefault "--delete-older-than 7d";
        };
        optimise = {
          automatic = lib.mkDefault true;
          dates = lib.mkDefault [ "weekly" ];
        };
      };

      # Locale
      i18n = {
        defaultLocale = lib.mkDefault "en_GB.UTF-8";
        extraLocaleSettings = {
          LC_ADDRESS = "en_GB.UTF-8";
          LC_IDENTIFICATION = "en_GB.UTF-8";
          LC_MEASUREMENT = "en_GB.UTF-8";
          LC_MONETARY = "en_GB.UTF-8";
          LC_NAME = "en_GB.UTF-8";
          LC_NUMERIC = "en_GB.UTF-8";
          LC_PAPER = "en_GB.UTF-8";
          LC_TELEPHONE = "en_GB.UTF-8";
          LC_TIME = "en_GB.UTF-8";
        };
      };
      time.timeZone = "Europe/London";
      services.xserver.xkb = { layout = "gb"; variant = ""; };
      console.keyMap = "uk";

      security.sudo.extraConfig = ''
        Defaults secure_path="/run/wrappers/bin:/run/current-system/sw/bin:/nix/var/nix/profiles/default/bin:/usr/local/bin:/usr/bin:/bin"
      '';
    };

    homeManager = { pkgs, config, ... }: {
      home.sessionVariables.NH_SEARCH_CHANNEL = "nixos-unstable";

      # Sops (HM)
      sops = {
        age = {
          generateKey = true;
          keyFile = "/home/${config.home.username}/.config/sops/age/keys.txt";
          sshKeyPaths = [ "/home/${config.home.username}/.ssh/id_ed25519" ];
        };
        defaultSymlinkPath = "/run/user/1000/secrets";
        defaultSecretsMountPoint = "/run/user/1000/secrets.d";
      };

      # ZSA keyboard tool
      home.packages = [ pkgs.keymapp ];

      browsers.firefox.enable = true;
      cli = {
        terminals.foot.enable = true;
        terminals.ghostty.enable = true;
        tools.core-tools.enable = true;
        tools.zk.enable = true;
        shells.fish.enable = true;
      };
      development.cloud.k8s.enable = true;
      programs = {
        guis.enable = true;
        nautilus.enable = true;
      };
    };
  };
}
