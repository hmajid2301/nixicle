_: {
  den.aspects.server-console = {
    nixos =
      {
        config,
        lib,
        pkgs,
        ...
      }:
      {
        options.nixicle.serverConsole = {
          enable = lib.mkOption {
            type = lib.types.bool;
            default = false;
            description = "Whether to auto-attach a persistent zellij console session for a server user.";
          };

          user = lib.mkOption {
            type = lib.types.str;
            default = "nixos";
            description = "User whose fish/zellij config should receive the server console setup.";
          };

          sessionName = lib.mkOption {
            type = lib.types.str;
            default = "main";
            description = "Zellij session name used for the persistent server console.";
          };
        };

        config = lib.mkIf config.nixicle.serverConsole.enable {
          environment.systemPackages = with pkgs; [ zellij ];

          programs.fish.interactiveShellInit = lib.mkAfter ''
            if not set -q ZELLIJ; and status is-interactive
              exec zellij attach --create ${config.nixicle.serverConsole.sessionName} options --default-layout bare
            end
          '';

          system.activationScripts.zellij-config = lib.stringAfter [ "users" ] ''
            mkdir -p /home/${config.nixicle.serverConsole.user}/.config/zellij/layouts
            chown ${config.nixicle.serverConsole.user}:users \
              /home/${config.nixicle.serverConsole.user}/.config \
              /home/${config.nixicle.serverConsole.user}/.config/zellij \
              /home/${config.nixicle.serverConsole.user}/.config/zellij/layouts
            install -o ${config.nixicle.serverConsole.user} -g users -m 0644 ${pkgs.writeText "server-console-zellij-config" ''
              default_layout "bare"
              simplified_ui true
              pane_frames false
              copy_on_select true
              show_startup_tips false
            ''} /home/${config.nixicle.serverConsole.user}/.config/zellij/config.kdl
            install -o ${config.nixicle.serverConsole.user} -g users -m 0644 ${pkgs.writeText "server-console-zellij-layout-bare" ''
              layout {
                pane
              }
            ''} /home/${config.nixicle.serverConsole.user}/.config/zellij/layouts/bare.kdl
          '';
        };
      };
  };
}
