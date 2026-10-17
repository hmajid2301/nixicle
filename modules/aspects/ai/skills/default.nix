_: {
  flake-file = {
    inputs = {
      agent-skills.url = "github:Kyure-A/agent-skills-nix";
      matt-skills = {
        url = "github:mattpocock/skills";
        flake = false;
      };
      gitlab-ci-skill = {
        url = "git+https://gitlab.com/gitlab-org/ci-cd/gitlab-ci-skill.git";
        flake = false;
      };
      playwright-cli-skill = {
        url = "github:microsoft/playwright-cli";
        flake = false;
      };
      superpowers = {
        url = "github:obra/superpowers";
        flake = false;
      };
      caveman = {
        url = "github:JuliusBrussee/caveman";
        flake = false;
      };
      herdr-skills = {
        url = "github:herdrdev/herdr/v0.9.3";
        flake = false;
      };
      pauldambra-dotfiles = {
        url = "github:pauldambra/dotfiles";
        flake = false;
      };
      i-have-adhd = {
        url = "github:ayghri/i-have-adhd";
        flake = false;
      };
      ponytail = {
        url = "github:DietrichGebert/ponytail";
        flake = false;
      };
      visual-explainer = {
        url = "github:nicobailon/visual-explainer";
        flake = false;
      };
      slidev-skills = {
        url = "github:yoanbernabeu/slidev-skills";
        flake = false;
      };
    };
  };

  den.aspects.skills = {
    homeManager =
      { inputs, config, ... }:
      {
        imports = [ inputs.agent-skills.homeManagerModules.default ];

        programs.agent-skills = {
          enable = true;

          sources = {
            matt = {
              path = inputs.matt-skills;
              subdir = "skills";
              idPrefix = "matt";
            };

            nixicle = {
              path = ./.;
              idPrefix = "nixicle";
            };

            gitlab-ci = {
              path = inputs.gitlab-ci-skill;
            };

            playwright-cli = {
              path = inputs.playwright-cli-skill;
              subdir = "skills";
            };

            superpowers = {
              path = inputs.superpowers;
              subdir = "skills";
              idPrefix = "superpowers";
            };

            caveman = {
              path = inputs.caveman;
              subdir = "skills";
            };

            herdr = {
              path = inputs.herdr-skills;
              subdir = "skills";
            };

            pauldambra = {
              path = inputs.pauldambra-dotfiles;
              subdir = "ai/skills";
            };

            adhd = {
              path = inputs.i-have-adhd;
              subdir = "skills";
            };

            ponytail = {
              path = inputs.ponytail;
              subdir = "skills";
            };

            visual-explainer = {
              path = inputs.visual-explainer;
              subdir = "plugins";
            };

            slidev = {
              path = inputs.slidev-skills;
              subdir = "skills";
              idPrefix = "slidev";
            };
          };

          skills = {
            enable = [
              "matt/engineering/wayfinder"
              "matt/productivity/teach"
              "matt/productivity/grill-me"
              "matt/productivity/grilling"
              "matt/productivity/handoff"
              "matt/productivity/to-questionnaire"
              "matt/productivity/wait-what"
              "matt/engineering/improve-codebase-architecture"
            ];

            enableAll = [
              "superpowers"
              "slidev"
            ];

            explicit = {
              zellij = {
                from = "nixicle";
                path = "zellij";
              };

              zk = {
                from = "nixicle";
                path = "zk";
              };

              atomic-committer = {
                from = "nixicle";
                path = "atomic-committer";
              };

              context-reset-handoff = {
                from = "nixicle";
                path = "context-reset-handoff";
              };

              session-summary = {
                from = "nixicle";
                path = "session-summary";
              };

              terraform-specialist = {
                from = "nixicle";
                path = "terraform-specialist";
              };

              database-admin = {
                from = "nixicle";
                path = "database-admin";
              };

              database-optimizer = {
                from = "nixicle";
                path = "database-optimizer";
              };

              test-automator = {
                from = "nixicle";
                path = "test-automator";
              };

              code-reviewer = {
                from = "nixicle";
                path = "code-reviewer";
              };

              thermo-nuclear-code-quality-review = {
                from = "nixicle";
                path = "thermo-nuclear-code-quality-review";
              };

              papercuts = {
                from = "nixicle";
                path = "papercuts";
              };

              caveman = {
                from = "caveman";
                path = "caveman";
              };

              "gitlab-ci-skill" = {
                from = "gitlab-ci";
                path = ".";
              };

              hister = {
                from = "nixicle";
                path = "hister";
              };

              karpathy-guidelines = {
                from = "nixicle";
                path = "karpathy-guidelines";
              };

              debugging = {
                from = "nixicle";
                path = "debugging";
              };

              "playwright-cli" = {
                from = "playwright-cli";
                path = "playwright-cli";
              };

              herdr = {
                from = "herdr";
                path = "herdr";
              };

              "review-triage" = {
                from = "pauldambra";
                path = "review-triage";
              };

              "qa-swarm" = {
                from = "pauldambra";
                path = "qa-swarm";
              };

              "i-have-adhd" = {
                from = "adhd";
                path = "i-have-adhd";
              };

              ponytail = {
                from = "ponytail";
                path = "ponytail";
              };

              visual-explainer = {
                from = "visual-explainer";
                path = "visual-explainer";
                transform =
                  { original, ... }:
                  original
                  + ''

                    ## Command procedures

                    The per-command workflows live in `./commands/`: `diff-review.md`, `plan-review.md`, `project-recap.md`, `fact-check.md`, `generate-web-diagram.md`, `generate-visual-plan.md`, `generate-slides.md`. Read the matching one before starting that task.

                    No native `visual_explainer` tool is installed here; write the HTML with the normal file tools and open it with `xdg-open`.
                  '';
              };
            };
          };

          targets.agents.enable = true;
          targets.claude.enable = config.programs.claude-code.enable;
        };
      };
  };
}
