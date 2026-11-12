{
  config,
  pkgs,
  ...
}:
{
  config.home.file."${config.xdg.configHome}/pi/agent/themes/stylix.json".source =
    let
      s = config.lib.stylix.colors.withHashtag;
    in
    pkgs.writeText "stylix.json" (
      builtins.toJSON {
        "$schema" =
          "https://raw.githubusercontent.com/badlogic/pi-mono/main/packages/coding-agent/src/modes/interactive/theme/theme-schema.json";
        name = "stylix";
        vars = {
          bg = s.base00;
          bgLight = s.base01;
          selection = s.base02;
          comment = s.base03;
          fgDark = s.base04;
          fg = s.base05;
          red = s.base08;
          orange = s.base09;
          yellow = s.base0A;
          green = s.base0B;
          cyan = s.base0C;
          blue = s.base0D;
          magenta = s.base0E;
          lavender = s.base07;
        };
        colors = {
          accent = "lavender";
          border = "comment";
          borderAccent = "lavender";
          borderMuted = "fgDark";
          success = "green";
          error = "red";
          warning = "yellow";
          muted = "fgDark";
          dim = "comment";
          text = "";
          thinkingText = "fgDark";
          selectedBg = "selection";
          userMessageBg = "bgLight";
          userMessageText = "";
          customMessageBg = "bgLight";
          customMessageText = "";
          customMessageLabel = "lavender";
          toolPendingBg = "bgLight";
          toolSuccessBg = "bgLight";
          toolErrorBg = "bgLight";
          toolTitle = "lavender";
          toolOutput = "";
          mdHeading = "yellow";
          mdLink = "blue";
          mdLinkUrl = "fgDark";
          mdCode = "cyan";
          mdCodeBlock = "";
          mdCodeBlockBorder = "fgDark";
          mdQuote = "fgDark";
          mdQuoteBorder = "fgDark";
          mdHr = "comment";
          mdListBullet = "cyan";
          toolDiffAdded = "green";
          toolDiffRemoved = "red";
          toolDiffContext = "fgDark";
          syntaxComment = "comment";
          syntaxKeyword = "magenta";
          syntaxFunction = "blue";
          syntaxVariable = "orange";
          syntaxString = "green";
          syntaxNumber = "cyan";
          syntaxType = "yellow";
          syntaxOperator = "cyan";
          syntaxPunctuation = "fgDark";
          thinkingOff = "comment";
          thinkingMinimal = "blue";
          thinkingLow = "cyan";
          thinkingMedium = "lavender";
          thinkingHigh = "yellow";
          thinkingXhigh = "red";
          bashMode = "orange";
        };
      }
    );
}
