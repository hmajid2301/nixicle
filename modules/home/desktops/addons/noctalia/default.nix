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
    ];

    programs.noctalia-shell = {
      enable = true;
      systemd.enable = true;

      colors = with config.lib.stylix.colors.withHashtag; {
        # Proper Catppuccin Mocha colors using Stylix base16 mapping
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

          wallpaper = {
            enabled = true;
            directory = "/home/${config.home.username}/Pictures/Wallpapers";
            fillMode = "crop";
          };

          sessionMenu = {
            position = "center";
            enableCountdown = true;
          };

          notifications = {
            enabled = true;
            location = "top_right";
          };

          dock = {
            enabled = false;
          };
        }

        cfg.settings
      ];
    };
  };
}
