{
  config,
  lib,
  ...
}:
with lib;
with lib.nixicle;
let
  cfg = config.cli.tools.opencode;
in
{
  options.cli.tools.opencode = {
    enable = mkBoolOpt true "Enable OpenCode terminal-based AI coding assistant";

    extraCommands = mkOption {
      type = types.attrsOf types.str;
      default = { };
      description = "Additional custom commands for OpenCode";
      example = literalExpression ''
        {
          changelog = '''
            # Update Changelog Command
            Update CHANGELOG.md with a new entry for the specified version.
            Usage: /changelog [version] [change-type] [message]
          ''';
          commit = '''
            # Commit Command
            Create a git commit with proper message formatting.
          ''';
        }
      '';
    };

    extraSettings = mkOption {
      type = types.attrs;
      default = { };
      description = "Additional settings for OpenCode config.json";
      example = literalExpression ''
        {
          autoshare = true;
          autoupdate = false;
        }
      '';
    };
  };

  config = mkIf cfg.enable {
    xdg.configFile."opencode/themes/stylix-catppuccin.json".text =
      let
        colors = config.lib.stylix.colors.withHashtag;
      in
      builtins.toJSON {
        "$schema" = "https://opencode.ai/theme.json";
        theme = {
          primary = colors.base0E; # Mauve/Purple for primary
          secondary = colors.base0D; # Blue for secondary
          accent = colors.base07; # Lavender for accents
          error = colors.base08; # Red
          warning = colors.base09; # Peach/Orange
          success = colors.base0B; # Green
          info = colors.base0C; # Cyan/Teal

          text = colors.base05; # Main text
          textMuted = colors.base04; # Muted text

          background = colors.base00; # Base background
          backgroundPanel = colors.base01; # Darker panel
          backgroundElement = colors.base02; # Surface elements

          border = colors.base02;
          borderActive = colors.base07;
          borderSubtle = colors.base03;

          diffAdded = colors.base0B; # Green
          diffRemoved = colors.base08; # Red
          diffContext = colors.base04;
          diffHighlightAdded = colors.base0B;
          diffHighlightRemoved = colors.base08;
          diffAddedBg = colors.base02;
          diffRemovedBg = colors.base02;
          diffContextBg = colors.base00;
          diffLineNumber = colors.base04;
          diffAddedLineNumberBg = colors.base02;
          diffRemovedLineNumberBg = colors.base02;
          diffHunkHeader = colors.base07;

          markdownText = colors.base05;
          markdownHeading = colors.base0E; # Purple
          markdownLink = colors.base0D; # Blue
          markdownCode = colors.base0C; # Cyan
          markdownBlockQuote = colors.base04;
          markdownEmph = colors.base0F; # Pink
          markdownStrong = colors.base09; # Orange
          markdownImage = colors.base0A; # Yellow

          syntaxComment = colors.base03; # More visible than before
          syntaxKeyword = colors.base0E; # Purple (mauve)
          syntaxFunction = colors.base0D; # Blue
          syntaxVariable = colors.base05; # Text color
          syntaxString = colors.base0B; # Green
          syntaxNumber = colors.base09; # Peach
          syntaxType = colors.base0A; # Yellow
          syntaxOperator = colors.base0C; # Cyan
          syntaxPunctuation = colors.base04;
        };
      };

    programs.opencode = {
      enable = true;

      commands = cfg.extraCommands;

      settings = {
        model = "anthropic/claude-sonnet-4-20250514";
        autoshare = false;
        autoupdate = false;
        theme = lib.mkForce "stylix-catppuccin";
      }
      // cfg.extraSettings;
    };
  };
}
