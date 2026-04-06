{ den, ... }:
let
  sharedNixConfig = import ../../../old/modules/shared/nix-caches.nix;
in
{
  flake-file.inputs.nur.url = "github:nix-community/NUR";
  flake-file.inputs.gomod2nix = {
    url = "github:nix-community/gomod2nix";
    inputs.nixpkgs.follows = "nixpkgs";
  };
  flake-file.inputs.sops-nix = {
    url = "github:mic92/sops-nix";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  den.aspects.common = {
    includes = [ den.aspects.stylix den.aspects.boot ];

    nixos = { pkgs, lib, inputs, options, ... }: {
      nixpkgs.overlays = [
        inputs.nur.overlays.default
        inputs.gomod2nix.overlays.default
      ];

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

      browsers.firefox.enable = true;
      cli.shells.fish.enable = true;

      programs.foot = {
        enable = true;
        settings = {
          main = { shell = "fish"; pad = "15x15"; selection-target = "clipboard"; };
          scrollback.lines = 10000;
        };
      };

      programs.ghostty = {
        enable = true;
        enableFishIntegration = true;
        settings = {
          command = "fish";
          gtk-titlebar = false;
          gtk-tabs-location = "hidden";
          gtk-single-instance = true;
          window-padding-x = 6;
          window-padding-y = 6;
          copy-on-select = "clipboard";
          cursor-style = "block";
          confirm-close-surface = false;
          keybind = [
            "ctrl+shift+plus=increase_font_size:1"
            "ctrl+shift+minus=decrease_font_size:1"
            "ctrl+shift+0=reset_font_size"
            "shift+enter=text:\\u001b[13;2u"
          ];
        };
      };

      programs.zk = {
        enable = true;
        settings = {
          note = {
            language = "en"; default-title = "Untitled";
            filename = "{{id}}-{{slug title}}"; extension = "md"; template = "default.md";
            id-charset = "alphanum"; id-length = 8; id-case = "lower";
          };
          format.markdown = { hashtags = true; colon-tags = true; multiword-tags = false; };
          tool = { editor = "nvim"; pager = "less -FIRX"; fzf-preview = "bat -p --color always {-1}"; };
          lsp.diagnostics = { wiki-title = "hint"; dead-link = "error"; };
          alias = { ls = "zk list $@"; ed = "zk edit $@"; n = "zk new $@"; };
        };
      };

      programs.k9s.enable = true;

      home.packages = with pkgs; [
        keymapp

        # k8s tools
        kubectl kubectx kubelogin kubelogin-oidc stern kubernetes-helm kustomize fluxcd kubefwd

        # GUI apps
        trayscale foliate pwvucontrol
        sushi gnome-disk-utility totem gvfs loupe
        nautilus ffmpegthumbnailer nautilus-python gst_all_1.gst-libav
      ];

      xdg.systemDirs.data = [
        "${pkgs.nautilus}/share/gsettings-schemas/${pkgs.nautilus.name}"
      ];

      xdg.userDirs = { enable = true; createDirectories = true; };

      gtk.gtk3.bookmarks = [ "file://${config.home.homeDirectory}/Downloads" ];

      dconf.settings = {
        "org/gnome/nautilus/preferences" = {
          show-image-thumbnails = "always";
          thumbnail-limit = 10;
          show-directory-item-counts = "never";
          executable-text-activation = "ask";
          always-use-location-entry = false;
          default-folder-viewer = "icon-view";
          thumbnail-cache-time = 30;
          show-recent = false;
        };
        "org/gnome/nautilus/icon-view".captions = [ "none" "none" "none" ];
        "org/gnome/nautilus/list-view".use-tree-view = false;
        "org/gnome/desktop/privacy".remember-recent-files = false;
        "com/github/stunkymonkey/nautilus-open-any-terminal" = {
          terminal = "ghostty"; flatpak = "off";
          keybindings = "<Ctrl><Alt>t"; new-tab = false;
        };
      };
    };
  };
}
