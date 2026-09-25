{ den, inputs, ... }:
let
  sharedNixConfig = atticRoot: {
    substituters = [
      "https://attic.${atticRoot}/main"
      # "https://staging.attic.rs/attic-ci"
      "https://cache.nixos.org"
      "https://nix-community.cachix.org"
      "https://numtide.cachix.org"
      "https://niri.cachix.org"
    ];
    trusted-public-keys = [
      "main:+A4BR+E8F8FNe1YR6Uq8qGO5dVj8y1kaalW3kQ0WgXo="
      # "attic-ci:U5Sey4mUxwBXM3iFapmP0/ogODXywKLRNgRPQpEXxbo="
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "numtide.cachix.org-1:2ps1kLBUWjxIneOy1Ik6cQjb41X0iXVXeHigGmycPPE="
      "niri.cachix.org-1:Wv0OmO7PsuocRKzfDoJ3mulSl7Z6oezYhGhR+3W2964="
    ];
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    warn-dirty = false;
    use-xdg-base-directories = true;
  };
in
{
  flake-file.inputs.nur.url = "github:nix-community/NUR";
  flake-file.inputs.sops-nix = {
    url = "github:mic92/sops-nix";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  den.aspects.common = {
    includes = [
      den.aspects.stylix
      den.aspects.boot
      den.aspects.fish
      den.aspects.commonCli
      den.aspects.commonDesktopApps
      den.aspects.commonTerminals
      den.aspects.commonNotes
    ];

    nixos =
      {
        pkgs,
        inputs,
        lib,
        config,
        ...
      }:
      {
        nixpkgs.overlays = [ lib.nixicle.overlays.nur ];

        networking.firewall.enable = true;
        networking.networkmanager.enable = true;
        systemd.services.NetworkManager-wait-online.enable = false;

        services = {
          openssh = {
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
          pcscd.enable = true;
          udev = {
            packages = with pkgs; [ yubikey-personalization ];
            extraRules = ''
              ACTION=="remove",\
               ENV{ID_BUS}=="usb",\
               ENV{ID_MODEL_ID}=="0407",\
               ENV{ID_VENDOR_ID}=="1050",\
               ENV{ID_VENDOR}=="Yubico",\
               RUN+="${pkgs.systemd}/bin/loginctl lock-sessions"
            '';
          };
          xserver.xkb = {
            layout = "gb";
            variant = "";
          };
        };

        sops.age.sshKeyPaths = [ "/persist/etc/ssh/ssh_host_ed25519_key" ];

        # Token used by the nix daemon to authenticate against the private
        # `main` attic cache (see netrc-file in nix.settings). The same secret
        # is also consumed by the home-manager attic aspect for user-level nix.
        sops.secrets.netrc.sopsFile = lib.nixicle.secretsFile;

        security.pam.services = {
          login.u2fAuth = true;
          sudo.u2fAuth = true;
        };

        nix = {
          channel.enable = false;
          nixPath = [ "nixpkgs=flake:nixpkgs" ];
          settings = {
            trusted-users = [
              "@wheel"
              "root"
            ];
            auto-optimise-store = lib.mkDefault true;
            system-features = [
              "kvm"
              "big-parallel"
              "nixos-test"
            ];
            flake-registry = "";
            require-sigs = true;
            fallback = true;
            netrc-file = config.sops.secrets."netrc".path;
          }
          // sharedNixConfig config.nixicle.domains.root;
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
        console.keyMap = "uk";

        security.sudo.extraConfig = ''
          Defaults secure_path="/run/wrappers/bin:/run/current-system/sw/bin:/nix/var/nix/profiles/default/bin:/usr/local/bin:/usr/bin:/bin"
        '';
      };

    homeManager =
      { config, ... }:
      {
        imports = [ inputs.sops-nix.homeManagerModules.sops ];
        home.sessionVariables.NH_SEARCH_CHANNEL = "nixos-unstable";

        sops = {
          age = {
            generateKey = true;
            keyFile = "/home/${config.home.username}/.config/sops/age/keys.txt";
            sshKeyPaths = [ "/home/${config.home.username}/.ssh/id_ed25519" ];
          };
          defaultSymlinkPath = "/run/user/1000/secrets";
          defaultSecretsMountPoint = "/run/user/1000/secrets.d";
        };
      };
  };
}
