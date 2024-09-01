{
  config,
  pkgs,
  ...
}: {
  programs.nixvim = {
    plugins = {
      lsp.servers.dockerls.enable = true;
      lsp.servers.docker-compose-language-service.enable = true;

      lint = {
        lintersByFt = {
          docker = ["hadolint"];
        };

        linters = {
          hadolint = {
            cmd = "${pkgs.hadolint}/bin/hadolint";
          };
        };
      };
    };
  };
}
