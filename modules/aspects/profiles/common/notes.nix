{ ... }:
{
  den.aspects.commonNotes = {
    homeManager = {
      programs.zk = {
        enable = true;
        settings = {
          note = {
            language = "en";
            default-title = "Untitled";
            filename = "{{id}}-{{slug title}}";
            extension = "md";
            template = "default.md";
            id-charset = "alphanum";
            id-length = 8;
            id-case = "lower";
          };
          format.markdown = {
            hashtags = true;
            colon-tags = true;
            multiword-tags = false;
          };
          tool = {
            editor = "nvim";
            pager = "less -FIRX";
            fzf-preview = "bat -p --color always {-1}";
          };
          lsp.diagnostics = {
            wiki-title = "hint";
            dead-link = "error";
          };
          alias = {
            ls = "zk list $@";
            ed = "zk edit $@";
            n = "zk new $@";
          };
        };
      };
    };
  };
}
