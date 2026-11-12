{ inputs }:
let
  pkgs = import inputs.nixpkgs { system = "x86_64-linux"; };
  inherit (pkgs) lib;
  evaluate =
    settings:
    (inputs.home-manager.lib.homeManagerConfiguration {
      inherit pkgs;
      modules = [
        ./_home-manager.nix
        {
          home = {
            username = "test";
            homeDirectory = "/home/test";
            stateVersion = "26.05";
          };
          programs.tuios = settings;
        }
      ];
    }).config;
  disabled = evaluate {
    enablePiIntegration = true;
    enableClaudeCodeIntegration = true;
    enableFishIntegration = true;
    settings.daemon.ssh_agent = "follow";
  };
  defaults = evaluate { enable = true; };
  configured = evaluate {
    enable = true;
    package = pkgs.hello;
    settings.daemon.ssh_agent = "follow";
    enableFishIntegration = true;
    enablePiIntegration = true;
    enableClaudeCodeIntegration = true;
  };
in
lib.runTests {
  piExtension = "${disabled.xdg.configHome}/pi/agent/extensions/tuios-agent-state.ts";
  testDisabledHasNoEffects = {
    expr =
      !(disabled.xdg.configFile ? "tuios/config.d/10-nix.toml")
      && !(disabled.home.file ? piExtension)
      && !(disabled.programs.claude-code.settings ? hooks)
      && !(lib.hasInfix "ssh-agent-path" disabled.programs.fish.interactiveShellInit);
    expected = true;
  };
  testDefaultPackage = {
    expr = lib.elem pkgs.tuios defaults.home.packages;
    expected = true;
  };
  testNoUnrequestedConfigOrIntegrations = {
    expr =
      !(defaults.xdg.configFile ? "tuios/config.d/10-nix.toml")
      && !(defaults.xdg.configFile ? "tuios/config.toml")
      && !(defaults.home.file ? "${defaults.xdg.configHome}/pi/agent/extensions/tuios-agent-state.ts")
      && !(defaults.programs.claude-code.settings ? hooks);
    expected = true;
  };
  testPackageOverride = {
    expr = lib.elem pkgs.hello configured.home.packages;
    expected = true;
  };
  testConfigLeavesMainFileWritable = {
    expr =
      configured.xdg.configFile ? "tuios/config.d/10-nix.toml"
      && !(configured.xdg.configFile ? "tuios/config.toml");
    expected = true;
  };
  testFishUsesSelectedPackage = {
    expr = lib.hasInfix (builtins.unsafeDiscardStringContext "${lib.getExe' pkgs.hello "tuios"} ssh-agent-path") configured.programs.fish.interactiveShellInit;
    expected = true;
  };
  testClaudeUsesSelectedPackage = {
    expr = configured.programs.claude-code.settings.hooks.SessionStart;
    expected = [
      {
        hooks = [
          {
            type = "command";
            command = "${lib.getExe' pkgs.hello "tuios"} agent-hook claude-code --integration 3";
            timeout = 5;
          }
        ];
      }
    ];
  };
  testPiIntegrationEnabled = {
    expr =
      configured.home.file ? "${configured.xdg.configHome}/pi/agent/extensions/tuios-agent-state.ts";
    expected = true;
  };
  testFishRequiresAgentFollowing = {
    expr =
      lib.hasInfix "ssh-agent-path"
        (evaluate {
          enable = true;
          enableFishIntegration = true;
        }).programs.fish.interactiveShellInit;
    expected = false;
  };
}
