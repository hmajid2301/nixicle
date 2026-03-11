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
                pane {
                    name "secondary"
                    size "30%"
                }
            }
        }

        tab name="dev" {
            pane split_direction="horizontal" {
                pane {
                    name "dev-server"
                    command "nix"
                    args "develop" "--command" "fish" "-c" "echo 'Starting development server...' && task dev"
                }
                pane {
                    name "dev-logs"
                    size "30%"
                    command "fish"
                    args "-c" "echo 'Development logs and monitoring...'"
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
                pane {
                    name "ai-context"
                    size "30%"
                    command "fish"
                    args "-c" "echo 'AI Context & Notes' && fish"
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
