{lib, ...}: {
  programs.nixvim = {
    plugins = {
      auto-session = {
        enable = true;
        settings = {
          auto_save_enabled = true;
          auto_restore_enabled = true;
        };
      };

      mini = {
        enable = true;
        modules = {
          starter = {
            header = lib.concatLines [
              "███╗   ██╗██╗██╗  ██╗██╗   ██╗██╗███╗   ███╗"
              "████╗  ██║██║╚██╗██╔╝██║   ██║██║████╗ ████║"
              "██╔██╗ ██║██║ ╚███╔╝ ██║   ██║██║██╔████╔██║"
              "██║╚██╗██║██║ ██╔██╗ ╚██╗ ██╔╝██║██║╚██╔╝██║"
              "██║ ╚████║██║██╔╝ ██╗ ╚████╔╝ ██║██║ ╚═╝ ██║"
              "╚═╝  ╚═══╝╚═╝╚═╝  ╚═╝  ╚═══╝  ╚═╝╚═╝     ╚═╝"
            ];
            items = [
              {
                name = "Find File";
                action = "Telescope find_files follow=true no_ignore=true hidden=true";
                section = "";
              }
              {
                name = "Recent File";
                action = "Telescope oldfiles";
                section = "";
              }
              {
                name = "Copilot";
                action = "CopilotChat";
                section = "";
              }
              {
                name = "ChatGPT";
                action = "ChatGPT";
                section = "";
              }
              {
                name = "Quit";
                action = "qa";
                section = "";
              }
            ];
            footer = "I use Neovim btw!";
          };
        };
      };
    };
  };
}
