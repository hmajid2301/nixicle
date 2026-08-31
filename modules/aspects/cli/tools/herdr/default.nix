{ inputs, ... }:
{
  den.aspects.herdr = {
    homeManager =
      { pkgs, lib, ... }:
      let
        piIntegration = pkgs.runCommand "herdr-pi-agent-state.ts" { } ''
          export HOME="$TMPDIR/home"
          mkdir -p "$HOME/.pi/agent"
          ${pkgs.herdr}/bin/herdr integration install pi >/dev/null
          cp "$HOME/.pi/agent/extensions/herdr-agent-state.ts" "$out"
        '';
      in
      {
        programs.herdr = {
          enable = true;
          settings = {
            onboarding = false;
            theme = {
              # TODO: turn into stylix?
              name = "catppuccin";
            };
            terminal = {
              default_shell = "fish";
              shell_mode = "auto";
              new_cwd = "follow";
            };
            keys = {
              prefix = "ctrl+a";
              new_tab = "prefix+c";
              next_tab = "prefix+n";
              previous_tab = "prefix+p";
              switch_tab = "prefix+1..9";
              switch_workspace = "prefix+shift+1..9";
              focus_pane_left = "prefix+h";
              focus_pane_down = "prefix+j";
              focus_pane_up = "prefix+k";
              focus_pane_right = "prefix+l";
              split_vertical = "prefix+v";
              split_horizontal = "prefix+minus";
              command = [
                {
                  key = "prefix+f";
                  type = "plugin_action";
                  command = "herdr-float.toggle";
                  description = "Toggle floating shell";
                }
                {
                  key = "alt+h";
                  type = "plugin_action";
                  command = "herdr-splits.nav-left";
                  description = "Navigate left";
                }
                {
                  key = "alt+j";
                  type = "plugin_action";
                  command = "herdr-splits.nav-down";
                  description = "Navigate down";
                }
                {
                  key = "alt+k";
                  type = "plugin_action";
                  command = "herdr-splits.nav-up";
                  description = "Navigate up";
                }
                {
                  key = "alt+l";
                  type = "plugin_action";
                  command = "herdr-splits.nav-right";
                  description = "Navigate right";
                }
                {
                  key = "ctrl+alt+h";
                  type = "plugin_action";
                  command = "herdr-splits.resize-left";
                  description = "Resize left";
                }
                {
                  key = "ctrl+alt+j";
                  type = "plugin_action";
                  command = "herdr-splits.resize-down";
                  description = "Resize down";
                }
                {
                  key = "ctrl+alt+k";
                  type = "plugin_action";
                  command = "herdr-splits.resize-up";
                  description = "Resize up";
                }
                {
                  key = "ctrl+alt+l";
                  type = "plugin_action";
                  command = "herdr-splits.resize-right";
                  description = "Resize right";
                }
              ];
            };
            ui = {
              status_indicators = "symbols";
              window_title = "{hostname}: {workspace}";
              tab_bar_position = "top";
              hide_tab_bar_when_single_tab = true;
              tab_bar_right = [
                { type = "zoom"; }
              ];
              tab_bar_right_separator = " · ";
              sidebar_collapsed_mode = "hidden";
              sidebar_start_collapsed = true;
              accent = "#89b4fa";
              sidebar.agents.rows = [
                [
                  "state_icon"
                  "workspace"
                  "tab"
                ]
                [ "terminal_title_stripped" ]
              ];
            };
          };
        };

        home = {
          packages = [ pkgs.tmux ];

          activation.herdrPlugins = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
            ${pkgs.herdr}/bin/herdr plugin link ${inputs.plugins-herdr-float} --enabled || true
            ${pkgs.herdr}/bin/herdr plugin link ${inputs.plugins-herdr-splits} --enabled || true
          '';

          file.".pi/agent/extensions/herdr-agent-state.ts".source = piIntegration;
        };
      };
  };
}
