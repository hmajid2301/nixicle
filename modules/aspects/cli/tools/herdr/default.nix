{ inputs, ... }:
{
  flake-file.inputs = {
    herdr = {
      url = "github:herdrdev/herdr/v0.9.0";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    plugins-herdr-worktrunk = {
      url = "github:devashish2203/herdr-worktrunk";
      flake = false;
    };
  };

  den.aspects.herdr-cli = {
    homeManager =
      { pkgs, lib, ... }:
      let
        piIntegration = pkgs.runCommand "herdr-pi-agent-state.ts" { } ''
          export HOME="$TMPDIR/home"
          mkdir -p "$HOME/.pi/agent"
          ${herdrPackage}/bin/herdr integration install pi >/dev/null
          cp "$HOME/.pi/agent/extensions/herdr-agent-state.ts" "$out"
        '';

        herdrPackage = inputs.herdr.packages.${pkgs.stdenv.hostPlatform.system}.default;
        agent-session-sync = pkgs.callPackage ./plugins/agent-session-sync/_package.nix { };

        # The plugin's scripts shell out to the binary, so pin the store path
        # rather than relying on whatever PATH the plugin runner happens to have.
        sessionSyncPlugin = pkgs.runCommand "herdr-plugin-agent-session-sync" { } ''
          mkdir -p "$out"
          cp ${./plugins/agent-session-sync}/herdr-plugin.toml "$out/"
          cp ${./plugins/agent-session-sync}/*.sh "$out/"
          chmod +w "$out"/*.sh
          for f in "$out"/*.sh; do
            substituteInPlace "$f" \
              --replace-quiet 'AGENT_SESSION_SYNC_BIN:-agent-session-sync' \
                              'AGENT_SESSION_SYNC_BIN:-${lib.getExe agent-session-sync}'
          done
        '';

        # SSH host aliases whose agent transcripts should be mirrored locally.
        syncHosts = [ ];
      in
      {
        programs.herdr = {
          enable = true;
          package = herdrPackage;
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
                {
                  key = "prefix+shift+g";
                  type = "plugin_action";
                  command = "worktrunk.open";
                  description = "Worktree: switch / create from default branch";
                }
                {
                  key = "prefix+shift+c";
                  type = "plugin_action";
                  command = "worktrunk.open-current";
                  description = "Worktree: switch / create from current branch";
                }
                {
                  key = "prefix+shift+r";
                  type = "plugin_action";
                  command = "worktrunk.open-with-remotes";
                  description = "Worktree: switch / create from local or remote branches";
                }
                {
                  key = "prefix+shift+d";
                  type = "plugin_action";
                  command = "worktrunk.remove";
                  description = "Worktree: remove";
                }
                {
                  key = "prefix+shift+m";
                  type = "plugin_action";
                  command = "worktrunk.merge";
                  description = "Worktree: merge into target branch";
                }
                {
                  key = "prefix+shift+s";
                  type = "plugin_action";
                  command = "agent-session-sync.open";
                  description = "Sessions: browse mirrored transcripts";
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
          packages = [
            pkgs.tmux
            agent-session-sync
          ];

          activation.herdrPlugins = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
            ${herdrPackage}/bin/herdr plugin link ${inputs.plugins-herdr-float} --enabled || true
            ${herdrPackage}/bin/herdr plugin link ${inputs.plugins-herdr-splits} --enabled || true
            ${herdrPackage}/bin/herdr plugin link ${inputs.plugins-herdr-worktrunk} --enabled || true
            ${herdrPackage}/bin/herdr plugin link ${sessionSyncPlugin} --enabled || true
          '';

          file.".pi/agent/extensions/herdr-agent-state.ts".source = piIntegration;
        };

        # Mirror agent transcripts off each remote box so losing one does not
        # lose the conversations running on it. Add SSH host aliases here to
        # switch it on; empty means no units are generated.
        systemd.user.services = lib.listToAttrs (
          map (host: {
            name = "agent-session-sync-${host}";
            value = {
              Unit = {
                Description = "Mirror agent transcripts from ${host}";
                After = [ "network-online.target" ];
              };
              Service = {
                ExecStart = "${lib.getExe agent-session-sync} daemon ${host}";
                Restart = "on-failure";
                RestartSec = 60;
              };
              Install.WantedBy = [ "default.target" ];
            };
          }) syncHosts
        );
      };
  };
}
