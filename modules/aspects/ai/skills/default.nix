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
    };
  };

  den.aspects.skills = {
    homeManager =
      { inputs, pkgs, ... }:
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
              "matt/engineering/resolving-merge-conflicts"
              "matt/engineering/improve-codebase-architecture"
            ];

            enableAll = [ "superpowers" ];

            explicit = {
              zellij = {
                from = "nixicle";
                path = "zellij";
                packages = [ pkgs.zellij ];
                rewriteCommands = false;
              };

              zk = {
                from = "nixicle";
                path = "zk";
                packages = [ pkgs.zk ];
                rewriteCommands = false;
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

              caveman = {
                from = "caveman";
                path = "caveman";
              };

              "gitlab-ci-skill" = {
                from = "gitlab-ci";
                path = ".";
              };

              "playwright-cli" = {
                from = "playwright-cli";
                path = "playwright-cli";
              };
            };
          };

          targets.agents.enable = true;
        };
      };
  };
}
