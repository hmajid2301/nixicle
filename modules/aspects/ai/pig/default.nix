{
  inputs,
  ...
}:
{
  flake-file.inputs.pig = {
    url = "github:MichaelKinsy/PiG/v0.7.0";
  };

  den.aspects.pig = {
    homeManager =
      {
        config,
        pkgs,
        lib,
        ...
      }:
      let
        goExtensionNames = [
          "claude-code"
          "hello"
          "session-name"
        ];
        replacedTsExtensions = [ "session-name.ts" ];
        builtinExtensions = [
          "mcp"
          "codemode"
          "tool-search"
          "pig-login"
        ];
        subcommands = [
          "auth"
          "config"
          "diagnose"
          "docs"
          "extension"
          "extensions"
          "install"
          "list"
          "login"
          "logout"
          "package"
          "piglet"
          "reload"
          "remove"
          "status"
          "uninstall"
          "update"
          "version"
        ];
        piExtensionsDir = "${config.xdg.configHome}/pi/agent/extensions/";
        tsExtensions = lib.filter (
          path:
          lib.hasPrefix piExtensionsDir path
          && !(lib.elem (lib.removePrefix piExtensionsDir path) replacedTsExtensions)
        ) (lib.attrNames config.home.file);
        goExtensions = pkgs.callPackage ./_extensions.nix { extensionNames = goExtensionNames; };
        extensionArgs =
          lib.concatMap
            (path: [
              "-e"
              path
            ])
            (
              (map (n: "${goExtensions}/bin/${n}") goExtensionNames)
              ++ tsExtensions
              ++ map (n: "builtin:${n}") builtinExtensions
            );
        pigPackage = inputs.pig.packages.${pkgs.stdenv.hostPlatform.system}.default;
        pigWrapped = pkgs.writeShellApplication {
          name = "pig";
          text = ''
            export PIG_USE_PI_DIRS=1 PI_TELEMETRY=0 PI_SKIP_VERSION_CHECK=1 HERDR_AGENT=pi
            case "''${1:-}" in
              ${lib.concatStringsSep "|" subcommands}) exec ${lib.getExe pigPackage} "$@" ;;
            esac
            exec ${lib.getExe pigPackage} --no-extensions ${lib.escapeShellArgs extensionArgs} "$@"
          '';
        };
      in
      {
        home.packages = [ pigWrapped ];
      };
  };
}
