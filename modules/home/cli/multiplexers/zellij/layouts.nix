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
            pane split_direction="vertical" {
                pane {
                    name "claude-code"
                    command "fish"
                    args "-c" "echo 'AI Assistant Ready!' && echo 'Commands: claude-code, opencode' && fish"
                }
            }
        }

        ${statusbar}
    }
  '';

  default = ''
    layout {
        pane

        ${statusbar}
    }
  '';
}
