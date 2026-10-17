{ inputs, ... }:
{
  flake-file.inputs = {
    herdr-nix = {
      url = "github:herdrdev/herdr-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    plugins-herdr-worktrunk = {
      url = "github:devashish2203/herdr-worktrunk";
      flake = false;
    };
    plugins-herdr-resurrect = {
      url = "github:cantona/herdr-resurrect";
      flake = false;
    };
  };

  den.aspects.herdr-cli = {
    homeManager =
      {
        pkgs,
        lib,
        ...
      }:
      let
        integrationAsset = agent: "${inputs.herdr-skills}/src/integration/assets/${agent}";
        herdrPackage = inputs.herdr-nix.packages.${pkgs.stdenv.hostPlatform.system}.default;
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

        pluginPackages = [
          inputs.plugins-herdr-float
          inputs.plugins-herdr-splits
          inputs.plugins-herdr-worktrunk
          inputs.plugins-herdr-resurrect
          sessionSyncPlugin
        ];

        # https://github.com/nix-community/home-manager/pull/9815
        desiredPluginManifests = builtins.toJSON (map (p: "${p}/herdr-plugin.toml") pluginPackages);

        stalePluginIds = ''
          .result.plugins[]?
          | select((.manifest_path // "") | startswith($store))
          | select((.manifest_path as $p | $desired | index($p)) | not)
          | .plugin_id
        '';

        missingPluginManifests = ''
          ($desired - [.result.plugins[]?.manifest_path?])[]
        '';
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
            experimental = {
              pane_history = true;
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
                  key = "prefix+ctrl+s";
                  type = "plugin_action";
                  command = "ntindle.herdr-resurrect.save";
                  description = "Resurrect: save snapshot";
                }
                {
                  key = "prefix+ctrl+r";
                  type = "plugin_action";
                  command = "ntindle.herdr-resurrect.restore";
                  description = "Resurrect: restore last snapshot";
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

        xdg.configFile."herdr/plugins/config/ntindle.herdr-resurrect/settings.json".text = builtins.toJSON {
          autoRestore = true;
        };

        xdg.configFile."herdr/plugins/config/ntindle.herdr-resurrect/allowlist.txt".text = "*\n";

        home = {
          packages = [
            pkgs.tmux
            pkgs.nodejs
          ];

          activation.herdrPlugins = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
            registered="$(${herdrPackage}/bin/herdr plugin list --json 2>/dev/null || true)"

            printf '%s' "$registered" \
              | ${lib.getExe pkgs.jq} -r \
                --arg store "/nix/store/" \
                --argjson desired ${lib.escapeShellArg desiredPluginManifests} \
                ${lib.escapeShellArg stalePluginIds} \
              | while read -r id; do
                  [ -n "$id" ] && ${herdrPackage}/bin/herdr plugin unlink "$id" >/dev/null 2>&1 || true
                done

            printf '%s' "$registered" \
              | ${lib.getExe pkgs.jq} -r \
                --argjson desired ${lib.escapeShellArg desiredPluginManifests} \
                ${lib.escapeShellArg missingPluginManifests} \
              | while read -r manifest; do
                  [ -n "$manifest" ] && ${herdrPackage}/bin/herdr plugin link "$manifest" --enabled >/dev/null 2>&1 || true
                done
          '';

          file = {
            ".pi/agent/extensions/herdr-agent-state.ts".source =
              "${integrationAsset "pi"}/herdr-agent-state.ts";
            ".claude/hooks/herdr-agent-state.sh" = {
              source = "${integrationAsset "claude"}/herdr-agent-state.sh";
              executable = true;
            };
          };
        };
      };
  };
}
