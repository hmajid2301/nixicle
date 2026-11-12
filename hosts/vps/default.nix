{ den, ... }:
{
  den.aspects.vps = {
    includes = [
      den.aspects.performance-base
      den.aspects.server
      den.aspects.server-admin
      den.aspects.impermanence
      den.aspects.boot
      den.aspects.hardening-vps
      den.aspects.backup-restic
      den.aspects.attic-cache

      den.aspects.tailscale
      den.aspects.traefik
      den.aspects.anubis
      den.aspects.nfs-nas
      den.aspects.postgresql
      den.aspects.redis
      den.aspects.attic-server
      den.aspects.crowdsec
      den.aspects.openbao
      den.aspects.pocketid
      den.aspects.garage
      den.aspects.tangled
      den.aspects.gitlab-runner

      den.aspects.atuin
      den.aspects.banterbus
      den.aspects.goroutinely
      den.aspects.lettucego
      den.aspects.karakeep
      den.aspects.papra
      den.aspects.tandoor
      den.aspects.tinyauth
      den.aspects.otel-collector
      den.aspects.ollama
      den.aspects.monitoring
      den.aspects.monitoringAlerts
      den.aspects.gotify
      den.aspects.sure
      den.aspects.homepage
      den.aspects.dynacat
      den.aspects.hister
      den.aspects.immich

      den.aspects.fish
      (den.batteries.tty-autologin "nixos")
    ];

    nixos =
      {
        config,
        lib,
        pkgs,
        ...
      }:
      {
        imports = [
          ./hardware-configuration.nix
          ./disks.nix
        ];

        nixpkgs.config.permittedInsecurePackages = [ "garage-1.3.1" ];

        sops.defaultSopsFile = ./secrets.yaml;
        sops.secrets = {
          gitlab_runner_env = { };
          gitlab_runner_docker_env = { };
          nixos_hashed_password.neededForUsers = true;
          dynacat_env = {
            owner = "dynacat";
            group = "dynacat";
          };
        };

        nixicle = {
          serverAdmin = {
            enable = true;
            mediaGid = 3000;
            hashedPasswordFile = config.sops.secrets.nixos_hashed_password.path;
            shell = pkgs.fish;
          };

          crowdsec = {
            allowlist = [
              "82.165.193.60"
              "146.70.189.96"
            ];
            allowlistUris = [ "/api/add" ];
          };

          dynacat = {
            enable = true;
            environmentFile = config.sops.secrets.dynacat_env.path;
            settings = {
              theme = {
                background-color = "240 21 15";
                contrast-multiplier = 1.2;
                primary-color = "217 92 83";
                positive-color = "115 54 76";
                negative-color = "347 70 65";
              };

              auth = {
                secret-key = "\${DYNACAT_SECRET_KEY}";
                disable-password = true;
                oidc = {
                  issuer-url = "https://id.haseebmajid.dev";
                  client-id = "dynacat";
                  client-secret = "\${OIDC_CLIENT_SECRET}";
                  redirect-url = "https://dynacat.haseebmajid.dev/api/oidc/callback";
                  allowed-groups = [ "family" ];
                };
              };

              pages = [
                {
                  name = "Home";
                  columns = [
                    {
                      size = "small";
                      widgets = [
                        {
                          type = "server-stats";
                          servers = [
                            {
                              type = "local";
                              name = "vps";
                            }
                          ];
                        }
                        {
                          type = "torrenting";
                          hosts = [
                            {
                              url = "http://nas:8282";
                              username = "admin";
                              password = "\${QBIT_PASSWORD}";
                            }
                          ];
                        }
                        {
                          type = "monitor";
                          cache = "1m";
                          title = "Networking";
                          sites = [
                            {
                              title = "Tailscale Admin";
                              url = "https://login.tailscale.com/admin/machines";
                              icon = "si:tailscale";
                            }
                          ];
                        }
                      ];
                    }
                    {
                      size = "full";
                      widgets = [
                        {
                          type = "search";
                          autofocus = true;
                        }
                        {
                          type = "rss";
                          title = "News";
                          style = "horizontal-cards";
                          feeds = [ ];
                        }
                        {
                          type = "monitor";
                          cache = "1m";
                          title = "Services";
                          sites = [
                            {
                              title = "Jellyfin";
                              url = "https://jellyfin.haseebmajid.dev";
                              icon = "si:jellyfin";
                            }
                            {
                              title = "qBittorrent";
                              url = "http://nas:8282";
                              icon = "si:qbittorrent";
                            }
                            {
                              title = "Sonarr";
                              url = "https://sonarr.homelab.haseebmajid.dev";
                              icon = "si:sonarr";
                            }
                            {
                              title = "Radarr";
                              url = "https://radarr.homelab.haseebmajid.dev";
                              icon = "si:radarr";
                            }
                            {
                              title = "Prowlarr";
                              url = "https://prowlarr.homelab.haseebmajid.dev";
                              icon = "si:prowlarr";
                            }
                            {
                              title = "Seerr";
                              url = "https://seerr.homelab.haseebmajid.dev";
                              icon = "si:overseerr";
                            }
                            {
                              title = "Maintainerr";
                              url = "https://maintainerr.homelab.haseebmajid.dev";
                              icon = "mdi:delete-sweep";
                            }
                            {
                              title = "Immich";
                              url = "https://immich.haseebmajid.dev";
                              icon = "si:immich";
                            }
                            {
                              title = "Homepage";
                              url = "https://homepage.haseebmajid.dev";
                              icon = "mdi:home";
                            }
                            {
                              title = "ChangeDetection";
                              url = "https://changedetect.haseebmajid.dev";
                              icon = "si:changedetection";
                            }
                          ];
                        }
                      ];
                    }
                    {
                      size = "small";
                      widgets = [
                        {
                          type = "weather";
                          units = "metric";
                          hour-format = "24h";
                          location = "London, United Kingdom";
                        }
                        {
                          type = "bookmarks";
                          groups = [
                            {
                              title = "General";
                              links = [
                                {
                                  title = "Gmail";
                                  url = "https://mail.google.com/mail/u/0/";
                                }
                                {
                                  title = "Amazon";
                                  url = "https://www.amazon.com/";
                                }
                                {
                                  title = "Github";
                                  url = "https://github.com/";
                                }
                              ];
                            }
                            {
                              title = "Entertainment";
                              links = [
                                {
                                  title = "YouTube";
                                  url = "https://www.youtube.com/";
                                }
                                {
                                  title = "Prime Video";
                                  url = "https://www.primevideo.com/";
                                }
                                {
                                  title = "Disney+";
                                  url = "https://www.disneyplus.com/";
                                }
                              ];
                            }
                            {
                              title = "Social";
                              links = [
                                {
                                  title = "Reddit";
                                  url = "https://www.reddit.com/";
                                }
                                {
                                  title = "Twitter";
                                  url = "https://twitter.com/";
                                }
                                {
                                  title = "Instagram";
                                  url = "https://www.instagram.com/";
                                }
                              ];
                            }
                          ];
                        }
                      ];
                    }
                  ];
                }
              ];
            };
          };
        };

        security.sudo.wheelNeedsPassword = lib.mkForce false;

        users.users.haseeb = {
          extraGroups = lib.mkForce [ "docker" ];
          hashedPassword = "!";
          linger = true;
        };

        systemd.tmpfiles.rules = [
          "d /home/haseeb 0700 haseeb users -"
          "d /home/haseeb/projects 0700 haseeb users -"
        ];

        assertions = [
          {
            assertion = builtins.all (group: !builtins.elem group config.users.users.haseeb.extraGroups) [
              "wheel"
              "networkmanager"
            ];
            message = "The haseeb user must not belong to privileged groups";
          }
        ];

        networking = {
          hostName = "vps";
          useDHCP = lib.mkDefault true;
          interfaces.ens3.useDHCP = lib.mkDefault true;
          firewall.allowedTCPPorts = [ 22 ];
        };

        services = {
          dbus.implementation = "dbus";
          fwupd.enable = false;
          openssh = {
            enable = true;
            ports = [ 22 ];
            settings.PasswordAuthentication = lib.mkForce false;
          };
          tailscale.extraSetFlags = [ "--ssh" ];
          traefik.dynamicConfigOptions.http = lib.mkMerge [
            (lib.nixicle.mkTraefikService {
              name = "tuios";
              port = 7681;
              host = "127.0.0.1";
              middlewares = [
                "tailnet-only"
                "tinyauth"
              ];
            })
            (lib.nixicle.mkTraefikService {
              name = "jellyfin";
              port = 8096;
              subdomain = "jellyfin";
              domain = "haseebmajid.dev";
              host = "nas";
            })
            (lib.nixicle.mkAuthenticatedTraefikService {
              name = "seerr";
              port = 5055;
              host = "nas";
            })
            (lib.nixicle.mkAuthenticatedTraefikService {
              name = "sonarr";
              port = 8989;
              host = "nas";
            })
            (lib.nixicle.mkAuthenticatedTraefikService {
              name = "sonarr-anime";
              port = 8990;
              host = "nas";
            })
            (lib.nixicle.mkAuthenticatedTraefikService {
              name = "radarr";
              port = 7878;
              host = "nas";
            })
            (lib.nixicle.mkAuthenticatedTraefikService {
              name = "prowlarr";
              port = 9696;
              host = "nas";
            })
            (lib.nixicle.mkAuthenticatedTraefikService {
              name = "maintainerr";
              port = 6246;
              host = "nas";
            })
          ];
        };

        nix.settings = {
          trusted-users = [
            "root"
            "@wheel"
          ];
          experimental-features = [
            "nix-command"
            "flakes"
          ];
        };

        time.timeZone = lib.mkForce "UTC";

        environment.systemPackages = with pkgs; [
          jq
          mosh
          sqlite-interactive
        ];

        system = {
          backup.objects = {
            observability = {
              paths = [
                "/var/lib/prometheus2"
                "/var/lib/loki"
                "/var/lib/grafana"
              ];
              timerConfig = {
                OnCalendar = "daily";
                RandomizedDelaySec = "2h";
                Persistent = true;
              };
            };
            networking = {
              paths = [
                "/var/lib/traefik"
                "/var/lib/tailscale"
              ];
              timerConfig = {
                OnCalendar = "daily";
                RandomizedDelaySec = "3h";
                Persistent = true;
              };
            };
            haseeb = {
              paths = [ "/home/haseeb" ];
              exclude = [
                "/home/haseeb/.cache"
                "/home/haseeb/.local/share/Trash"
                "**/.direnv"
                "**/node_modules"
                "**/target"
              ];
              timerConfig = {
                OnCalendar = "daily";
                RandomizedDelaySec = "4h";
                Persistent = true;
              };
            };
          };
          stateVersion = "24.05";
        };
      };
  };
}
