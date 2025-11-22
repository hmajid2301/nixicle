{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
with lib;
let
  cfg = config.desktops.addons.noctalia;
in
{
  options.desktops.addons.noctalia = {
    enable = mkEnableOption "Enable Noctalia Shell";

    enableSystemd = mkOption {
      type = types.bool;
      default = true;
      description = "Enable systemd service for auto-start";
    };

    niri = {
      enableKeybinds = mkOption {
        type = types.bool;
        default = false;
        description = "Enable automatic keybinding configuration for niri";
      };

      enableSpawn = mkOption {
        type = types.bool;
        default = false;
        description = "Auto-start Noctalia with niri";
      };
    };

    settings = mkOption {
      type = types.attrs;
      default = { };
      description = "Additional settings to merge with the default configuration";
    };
  };

  config = mkIf cfg.enable {
    # Install fallback icon themes
    home.packages = [
      pkgs.hicolor-icon-theme # Fallback icon theme for missing icons
      pkgs.adwaita-icon-theme # Additional fallback with better coverage
    ];

    programs.noctalia-shell = {
      enable = true;
      systemd.enable = cfg.enableSystemd;

      colors = with config.lib.stylix.colors.withHashtag; {
        # Proper Catppuccin Mocha colors using Stylix base16 mapping
        mPrimary = base0E;           # #cba6f7 (mauve/lavender)
        mOnPrimary = "#11111b";      # crust (not in base16)
        mSecondary = base09;         # #fab387 (peach)
        mOnSecondary = "#11111b";    # crust
        mTertiary = base0C;          # #94e2d5 (teal)
        mOnTertiary = "#11111b";     # crust
        mError = base08;             # #f38ba8 (red)
        mOnError = "#11111b";        # crust
        mSurface = base00;           # #1e1e2e (base)
        mOnSurface = base05;         # #cdd6f4 (text)
        mSurfaceVariant = base02;    # #313244 (surface0)
        mOnSurfaceVariant = base07;  # #b4befe (lavender)
        mOutline = base04;           # #585b70 (surface2)
        mShadow = "#11111b";         # crust
        mHover = base03;             # #45475a (surface1)
        mOnHover = base05;           # #cdd6f4 (text)
      };

      settings = mkMerge [
        {
          # Basic configuration matching stylix
          ui = {
            fontDefault = config.stylix.fonts.sansSerif.name or "Noto Sans";
            fontFixed = config.stylix.fonts.monospace.name or "MonoLisa";
          };

          # Night light enabled by default
          nightLight = {
            enabled = true;
            autoSchedule = true;
            dayTemp = "6500";
            nightTemp = "4000";
          };

          # General settings
          general = {
            lockOnSuspend = true;
            avatarImage = "/home/${config.home.username}/.face";
          };

          # Bar configuration
          bar = {
            position = "top";
            exclusive = true;
            widgets = {
              left = [
                {
                  id = "Workspace";
                  labelMode = "index";
                  hideUnoccupied = false;
                }
                {
                  id = "ActiveWindow";
                  showIcon = true;
                  hideMode = "hidden";
                }
              ];
              center = [
                {
                  id = "Clock";
                  formatHorizontal = "HH:mm ddd, MMM dd";
                  usePrimaryColor = true;
                }
                {
                  id = "MediaMini";
                  hideWhenIdle = false;
                  showVisualizer = false;
                }
                {
                  id = "KeepAwake";
                }
              ];
              right = [
                {
                  id = "Tray";
                  drawerEnabled = true;
                }
                {
                  id = "NotificationHistory";
                  showUnreadBadge = true;
                  hideWhenZero = true;
                }
                {
                  id = "Volume";
                  displayMode = "onhover";
                }
                {
                  id = "ControlCenter";
                  icon = "noctalia";
                }
              ];
            };
          };

          # Wallpaper settings
          wallpaper = {
            enabled = true;
            directory = "/home/${config.home.username}/Pictures/Wallpapers";
            fillMode = "crop";
          };

          # Session menu (power options)
          sessionMenu = {
            position = "center";
            enableCountdown = true;
          };

          # Notifications
          notifications = {
            enabled = true;
            location = "top_right";
          };

          # Dock - disabled (using bar instead)
          dock = {
            enabled = false;
          };
        }

        # User custom settings override
        cfg.settings
      ];
    };

    # Note: Niri uses KDL config files, not Nix configuration
    # Users should add keybindings in their niri config.kdl file
    # Example keybindings for noctalia-shell:
    #
    # binds {
    #     Mod+Space { spawn "noctalia-shell" "ipc" "call" "launcher" "toggle"; }
    #     Mod+Shift+B { spawn "noctalia-shell" "ipc" "call" "controlCenter" "toggle"; }
    #     Mod+Shift+N { spawn "noctalia-shell" "ipc" "call" "notificationCenter" "toggle"; }
    #     Mod+L { spawn "noctalia-shell" "ipc" "call" "lockScreen" "toggle"; }
    # }
    #
    # For auto-start, add to spawn-at-startup in config.kdl:
    # spawn-at-startup { command "noctalia-shell"; }
  };
}
