{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.desktops.addons.noctalia;
in
{
  options.desktops.addons.noctalia = {
    enable = mkEnableOption "Enable Noctalia Shell";

    laptop = mkOption {
      type = types.bool;
      default = false;
      description = "Enable laptop-specific widgets (battery, brightness, WiFi)";
    };

    settings = mkOption {
      type = types.attrs;
      default = { };
      description = "Additional settings to merge with the default configuration";
    };
  };

  config = mkIf cfg.enable {
    home.packages = [
      pkgs.hicolor-icon-theme
      pkgs.adwaita-icon-theme
      pkgs.quickshell # Ensure qs command is available in PATH
    ];

    programs.noctalia-shell = {
      enable = true;
      systemd.enable = true;

      # TODO: use stylix only colours here.
      colors = with config.lib.stylix.colors.withHashtag; mkDefault {
        mPrimary = base0E; # #cba6f7 (mauve/lavender)
        mOnPrimary = "#11111b"; # crust (not in base16)
        mSecondary = base09; # #fab387 (peach)
        mOnSecondary = "#11111b"; # crust
        mTertiary = base0C; # #94e2d5 (teal)
        mOnTertiary = "#11111b"; # crust
        mError = base08; # #f38ba8 (red)
        mOnError = "#11111b"; # crust
        mSurface = base00; # #1e1e2e (base)
        mOnSurface = base05; # #cdd6f4 (text)
        mSurfaceVariant = base02; # #313244 (surface0)
        mOnSurfaceVariant = base07; # #b4befe (lavender)
        mOutline = base04; # #585b70 (surface2)
        mShadow = "#11111b"; # crust
        mHover = base03; # #45475a (surface1)
        mOnHover = base05; # #cdd6f4 (text)
      };

      settings = mkMerge [
        {
          appLauncher = {
            enableClipboardHistory = true;
          };

          ui = {
            fontDefault = config.stylix.fonts.sansSerif.name;
            fontFixed = config.stylix.fonts.monospace.name;
          };

          nightLight = {
            enabled = true;
            autoSchedule = true;
            dayTemp = "6500";
            nightTemp = "4000";
          };

          general = {
            lockOnSuspend = true;
            avatarImage = "/home/${config.home.username}/.face";
          };

          dock = {
            enabled = false;
          };

          bar = {
            floating = true;
            marginHorizontal = 0.25;
            marginVertical = 0.25;
            widgets = {
              left = [
                {
                  id = "Workspace";
                  characterCount = 2;
                }
              ];
              center = [
                {
                  id = "Clock";
                  formatHorizontal = "HH:mm:ss ddd, MMM dd";
                  usePrimaryColor = true;
                }
                {
                  id = "KeepAwake";
                }
              ];
              right = mkMerge [
                # Base widgets for all systems
                [
                  {
                    id = "Tray";
                  }
                  {
                    id = "NotificationHistory";
                    hideWhenZero = true;
                  }
                ]
                # Laptop-specific widgets (WiFi, Bluetooth, brightness, battery)
                (mkIf cfg.laptop [
                  {
                    id = "WiFi";
                    displayMode = "icon";
                  }
                  {
                    id = "Bluetooth";
                    displayMode = "icon";
                  }
                  {
                    id = "Brightness";
                    displayMode = "onhover";
                  }
                  {
                    id = "Battery";
                  }
                ])
                # Volume and control center for all systems
                [
                  {
                    id = "Volume";
                    displayMode = "onhover";
                  }
                  {
                    id = "ControlCenter";
                    icon = "noctalia";
                  }
                ]
              ];
            };
          };

          wallpaper = {
            directory = "/home/${config.home.username}/nixicle/packages/wallpapers/wallpapers";
            enableOverviewWallpaper = true;
          };

          osd = {
            monitors = [ "DP-1" ];
          };

          controlCenter = {
            shortcuts = {
              left = mkMerge [
                # WiFi always included (for all setups)
                [
                  { id = "WiFi"; }
                  { id = "Bluetooth"; }
                ]
                # Common shortcuts
                [
                  { id = "ScreenRecorder"; }
                  { id = "WallpaperSelector"; }
                ]
              ];
              right = mkMerge [
                (mkIf cfg.laptop [
                  { id = "PowerProfile"; }
                ])
                [
                  { id = "Notifications"; }
                  { id = "KeepAwake"; }
                  { id = "NightLight"; }
                ]
              ];
            };
          };
        }

        cfg.settings
      ];
    };
  };
}
