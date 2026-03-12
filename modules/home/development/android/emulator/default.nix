{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
with lib.nixicle;
let
  cfg = config.development.android.emulator;

  emulatorLauncher = pkgs.writeShellScriptBin "android-emulator" ''
    export QT_QPA_PLATFORM=xcb

    # Clear Nix-injected GL library paths so the emulator uses its own
    # bundled graphics stack and the system's GL/Vulkan drivers.
    unset __EGL_VENDOR_LIBRARY_FILENAMES
    unset GBM_BACKENDS_PATH
    export LD_LIBRARY_PATH=/lib/x86_64-linux-gnu:/usr/lib/x86_64-linux-gnu
    export LIBGL_DRIVERS_PATH=/usr/lib/x86_64-linux-gnu/dri

    EMULATOR_BIN="''${ANDROID_SDK_ROOT:-$HOME/Android/Sdk}/emulator/emulator"

    if [ ! -f "$EMULATOR_BIN" ]; then
      ${pkgs.gum}/bin/gum style --foreground 196 "Error: Android emulator not found at $EMULATOR_BIN"
      exit 1
    fi

    # Get list of available AVDs
    AVDS=$("$EMULATOR_BIN" -list-avds)

    if [ -z "$AVDS" ]; then
      ${pkgs.gum}/bin/gum style --foreground 196 "No Android Virtual Devices found!"
      ${pkgs.gum}/bin/gum style --foreground 33 "Create one using Android Studio or avdmanager"
      exit 1
    fi

    # Let user pick an AVD
    SELECTED=$(echo "$AVDS" | ${pkgs.gum}/bin/gum choose --header "Select an Android Virtual Device:")

    if [ -z "$SELECTED" ]; then
      ${pkgs.gum}/bin/gum style --foreground 33 "No AVD selected"
      exit 0
    fi

    ${pkgs.gum}/bin/gum style --foreground 42 "Launching $SELECTED..."

    # Launch the emulator with hardware GPU
    exec "$EMULATOR_BIN" -avd "$SELECTED" -gpu host "$@"
  '';
in
{
  options.development.android.emulator = with types; {
    enable = mkBoolOpt false "Whether to enable Android emulator launcher";
    
    sdkPath = mkOption {
      type = types.str;
      default = "$HOME/Android/Sdk";
      description = "Path to Android SDK";
    };
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      emulatorLauncher
      gum
      android-tools # Includes adb, fastboot, etc
    ];

    home.sessionVariables = {
      ANDROID_SDK_ROOT = cfg.sdkPath;
      ANDROID_HOME = cfg.sdkPath;
    };
    
    # Wrapper script to ensure adb works with your existing SDK
    home.file.".local/bin/adb-wrapper".source = pkgs.writeShellScript "adb-wrapper" ''
      export ANDROID_SDK_ROOT="${cfg.sdkPath}"
      export ANDROID_HOME="${cfg.sdkPath}"
      exec ${pkgs.android-tools}/bin/adb "$@"
    '';
  };
}
