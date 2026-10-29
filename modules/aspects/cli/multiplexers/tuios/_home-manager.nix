{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.tuios;
  toml = pkgs.formats.toml { };
  tuios = lib.getExe' cfg.package "tuios";
  piIntegration = pkgs.runCommand "tuios-pi-integration" { } ''
    export HOME="$TMPDIR/home"
    export PI_CODING_AGENT_DIR="$HOME/.pi/agent"
    mkdir -p "$PI_CODING_AGENT_DIR"
    ${tuios} integration install pi --command ${tuios}
    cp "$PI_CODING_AGENT_DIR/extensions/tuios-agent-state.ts" "$out"
  '';
in
{
  options.programs.tuios = {
    enable = lib.mkEnableOption "TUIOS terminal multiplexer";
    package = lib.mkPackageOption pkgs "tuios" { };
    settings = lib.mkOption {
      inherit (toml) type;
      default = { };
      description = "TOML defaults written to tuios/config.d/10-nix.toml; writable config.toml overrides them.";
    };
    enableFishIntegration = lib.mkEnableOption "TUIOS SSH-agent following in Fish";
    enablePiIntegration = lib.mkEnableOption "TUIOS state reporting from Pi";
    enableClaudeCodeIntegration = lib.mkEnableOption "TUIOS state reporting from Claude Code";
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ cfg.package ];

    xdg.configFile."tuios/config.d/10-nix.toml" = lib.mkIf (cfg.settings != { }) {
      source = toml.generate "tuios-defaults.toml" cfg.settings;
    };

    programs.fish.interactiveShellInit =
      lib.mkIf (cfg.enableFishIntegration && (cfg.settings.daemon.ssh_agent or "off") == "follow")
        ''
          if test "$TUIOS_ENV" = 1
            set -l agent_socket (${tuios} ssh-agent-path 2>/dev/null)
            if test $status -eq 0; and test -n "$agent_socket"
              set -gx SSH_AUTH_SOCK "$agent_socket"
            end
          end
        '';

    home.file.".pi/agent/extensions/tuios-agent-state.ts" = lib.mkIf cfg.enablePiIntegration {
      source = piIntegration;
    };

    programs.claude-code.settings.hooks = lib.mkIf cfg.enableClaudeCodeIntegration (
      lib.genAttrs
        [
          "SessionStart"
          "UserPromptSubmit"
          "PreToolUse"
          "PermissionRequest"
          "PostToolUse"
          "PostToolUseFailure"
          "PermissionDenied"
          "ElicitationResult"
          "Notification"
          "Stop"
          "StopFailure"
          "SessionEnd"
          "SubagentStart"
          "SubagentStop"
        ]
        (event: [
          {
            hooks = [
              {
                type = "command";
                command = "${tuios} agent-hook claude-code --integration 3";
                timeout = if event == "PermissionRequest" then 310 else 5;
              }
            ];
          }
        ])
    );
  };
}
