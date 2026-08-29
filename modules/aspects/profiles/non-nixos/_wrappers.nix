{
  pkgs,
  config,
  lib,
  inputs,
  ...
}:
{
  targets.genericLinux.nixGL = {
    inherit (inputs.nixgl) packages;
    defaultWrapper = "mesa";
  };

  nixpkgs.overlays = [
    (_final: prev: {
      nautilus = prev.nautilus.overrideAttrs (old: {
        postFixup = (old.postFixup or "") + ''
          mv $out/bin/nautilus $out/bin/.nautilus-gdk-wrapped
          makeWrapper $out/bin/.nautilus-gdk-wrapped $out/bin/nautilus \
            --unset GDK_PIXBUF_MODULE_FILE
        '';
      });
    })
  ];

  home.packages = with pkgs; [
    inputs.nixgl.packages.${pkgs.stdenv.hostPlatform.system}.nixGLIntel
    gdk-pixbuf
    webp-pixbuf-loader
    (lib.hiPrio (
      config.lib.nixGL.wrap (
        pkgs.writeShellScriptBin "google-chrome" ''
          unset LIBVA_DRIVERS_PATH LIBGL_DRIVERS_PATH __EGL_VENDOR_LIBRARY_FILENAMES GBM_BACKENDS_PATH
          export LD_LIBRARY_PATH=$(echo "$LD_LIBRARY_PATH" | tr ':' '\n' | grep -v -E 'mesa|libglvnd|libgl1' | tr '\n' ':' | sed 's/:*$//')
          exec /usr/bin/google-chrome-stable \
            --no-sandbox \
            --enable-features=UseOzonePlatform,VaapiVideoDecodeLinuxGL \
            --ozone-platform=wayland \
            "$@"
        ''
      )
    ))
  ];

  programs = {
    firefox.package = lib.mkForce (config.lib.nixGL.wrap pkgs.firefox);
    ghostty.package = lib.mkForce (config.lib.nixGL.wrap pkgs.ghostty);
  };
}
