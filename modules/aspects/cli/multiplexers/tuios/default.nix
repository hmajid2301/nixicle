{ inputs, ... }:
{
  flake-file.inputs.tuios.url = "github:Gaurav-Gosain/tuios/v0.12.1";
  flake.homeModules.tuios = ./_home-manager.nix;

  den.aspects.tuios.homeManager =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      imports = [ ./_home-manager.nix ];

      xdg.configFile."tuios/themes/catppuccin_mocha_chrome.json".text = builtins.toJSON {
        display_name = "Catppuccin Mocha Chrome";
        base = "catppuccin_mocha";
        chrome = {
          accent = "#b4befe";
          accent_bright = "#b4befe";
          canvas = "#11111b";
          surface = "#181825";
          panel = "#313244";
          card = "#1e1e2e";
        };
      };

      programs.tuios = {
        enable = true;
        # TODO: upstream the segmented dock style to Gaurav-Gosain/tuios, then drop this patch
        package = inputs.tuios.packages.${pkgs.stdenv.hostPlatform.system}.tuios.overrideAttrs (old: {
          patches = (old.patches or [ ]) ++ [ ./_segmented-tabs.patch ];
          postCheck = (old.postCheck or "") + ''
            go test ./internal/app ./internal/config -run 'TestSegmentedDock|TestPalette|TestLook'
          '';
        });
        enableFishIntegration = true;
        enablePiIntegration = true;
        enableClaudeCodeIntegration = config.programs.claude-code.enable;
        settings = {
          daemon.ssh_agent = "follow";
          startup = {
            daemon = true;
            tiled = true;
            open_default_window = true;
            start_in_terminal_mode = true;
          };
          workspaces.new_window_when_empty = true;
          agents.permissions = {
            mode = "strict";
            grants = [
              "read"
              "write"
              "fan"
            ];
          };
          appearance = {
            preferred_shell = lib.getExe pkgs.fish;
            theme = "catppuccin_mocha_chrome";
            background = "theme";
            desktop_background = "#11111b";
            dock_background = "#181825";
            sidebar = {
              enabled = true;
              position = "left";
              background = "#181825";
              header_style = "plain";
              row_style = "pill";
            };
            border_style = "rounded";
            border_focused_color = "#b4befe";
            border_focused_gradient = "#b4befe #cba6f7";
            border_gradient_angle = 30;
            border_unfocused_color = "#45475a";
            gap = 1;
            dim_unfocused = 8;
            dim_foreground = false;
            hide_window_buttons = true;
            hide_scrollbar = true;
            window_title_format = "{index}: {title}";
            window_title_style = "pill";
            window_title_align = "center";
            dockbar_position = "top";
            dock_compact = true;
            dock_pill_caps = true;
            dock_workspace_tabs = true;
            dock_workspace_tab_format = "{icon}  {name}";
            dock_workspace_label_max = 32;
            show_clock = true;
            clock_format = "15:04";
            panel_padding = 1;
            modal_dim = 45;
            nvim_navigation = true;
          };
          dock = {
            left = [
              "mode"
              "workspaces"
            ];
            center = [ ];
            right = [ "clock" ];
            tabs = {
              style = "segmented";
              cap_colors = [
                "#b4befe"
                "#cba6f7"
                "#a6e3a1"
                "#fab387"
                "#89b4fa"
                "#f5c2e7"
              ];
              number_glyphs = [
                "󰚩"
                ""
                ""
              ];
            };
          };
        };
      };
    };
}
