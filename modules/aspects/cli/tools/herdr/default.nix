_: {
  den.aspects.herdr = {
    homeManager =
      { pkgs, ... }:
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
            theme.name = "terminal";
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
                  key = "alt+f";
                  type = "plugin_action";
                  command = "herdr-float.toggle";
                  description = "Toggle floating shell";
                }
              ];
            };
            ui = {
              status_indicators = "symbols";
              window_title = "{hostname}: {workspace}";
            };
            worktrees.directory = "~/worktrees";
          };
        };

        home.packages = [ pkgs.tmux ];

        home.file.".pi/agent/extensions/herdr-agent-state.ts".source = piIntegration;
      };
  };
}
