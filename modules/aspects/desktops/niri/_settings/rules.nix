{ lib, ... }:
{
  _children = lib.mkAfter [
    {
      "window-rule" = {
        geometry-corner-radius = [
          10.0
          10.0
          10.0
          10.0
        ];
        clip-to-geometry = true;
      };
    }
    {
      "window-rule" = {
        _children = [
          {
            match._props = {
              app-id = "^google-chrome$";
              title = ".*Meet.*";
            };
          }
          {
            match._props = {
              app-id = "^google-chrome$";
              title = ".*meet\\.google\\.com.*";
            };
          }
          {
            match._props = {
              app-id = "^google-chrome$";
              title = ".*Google Meet.*";
            };
          }
          {
            match._props = {
              app-id = "^google-chrome$";
              title = ".*Zoom.*";
            };
          }
          {
            match._props = {
              app-id = "^google-chrome$";
              title = ".*zoom\\.us.*";
            };
          }
          {
            match._props = {
              app-id = "^google-chrome$";
              title = ".*Join Zoom Meeting.*";
            };
          }
          {
            match._props = {
              app-id = "^google-chrome$";
              title = "^$";
            };
          }
          {
            match._props = {
              app-id = "^firefox$";
              title = ".*PayPal.*";
            };
          }
          {
            match._props = {
              app-id = "^firefox$";
              title = ".*popup.*";
            };
          }
          {
            match._props = {
              app-id = "^firefox$";
              title = ".*Authentication.*";
            };
          }
          {
            match._props = {
              app-id = "^firefox$";
              title = ".*Login.*";
            };
          }
          {
            match._props = {
              app-id = "^firefox$";
              title = ".*Security.*";
            };
          }
          {
            match._props = {
              app-id = "^org.mozilla.firefox$";
              title = ".*PayPal.*";
            };
          }
          {
            match._props = {
              app-id = "^org.mozilla.firefox$";
              title = ".*popup.*";
            };
          }
          {
            match._props = {
              app-id = "^firefox$";
              title = ".*Bitwarden.*";
            };
          }
          {
            match._props = {
              app-id = "^org.mozilla.firefox$";
              title = ".*Bitwarden.*";
            };
          }
          {
            match._props = {
              app-id = "^firefox$";
              title = ".*Extension.*Bitwarden.*";
            };
          }
          {
            match._props = {
              app-id = "^bitwarden$";
            };
          }
          {
            match._props = {
              app-id = "^com.bitwarden.desktop$";
            };
          }
          {
            match._props = {
              app-id = "^firefox$";
              title = "^$";
            };
          }
          {
            match._props = {
              app-id = "^org.mozilla.firefox$";
              title = "^$";
            };
          }
        ];
        default-column-width = { };
        open-on-output = "";
        open-maximized = false;
        open-fullscreen = false;
      };
    }
    {
      "layer-rule" = {
        _children = [
          {
            match._props = {
              namespace = "^noctalia-overview.*";
            };
          }
        ];
        place-within-backdrop = true;
      };
    }
  ];

  gestures.hot-corners.off = { };
}
