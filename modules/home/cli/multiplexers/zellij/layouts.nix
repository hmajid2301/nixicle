{ statusbar }:
{
  dev = ''
    layout {
        tab name="code" focus=true {
            pane {
                command "nvim"
                args "."
            }
        }

        tab name="exec" {
            pane split_direction="vertical" {
                pane {
                    name "main"
                }
            }
        }

        tab name="ai" {
            pane {
                name "ai-assistant"
                command "fish"
                args "-c" "set ai_tool (string lower $GSESH_AI_TOOL); if test \"$ai_tool\" = \"claude\"; claude -c; else; opencode -c; end; exec fish"
            }
        }

        ${statusbar}
    }
  '';

  default = ''
    layout {
        ${statusbar}

        tab {
            pane
        }
    }
  '';
}
