{ pkgs, ... }:
{
  lspsAndRuntimeDeps = {
    general = with pkgs; [
      universal-ctags
      ripgrep
      fd
      stdenv.cc.cc
    ];
    css = with pkgs; [
      stylelint
      prettierd
      rustywind
      tailwindcss-language-server
    ];
    docker = with pkgs; [
      dockerfile-language-server
      docker-compose-language-service
      hadolint
    ];
    html = with pkgs; [
      htmlhint
      rubyPackages_3_4.htmlbeautifier
      htmx-lsp
      vscode-langservers-extracted
      svelte-language-server
    ];
    go = with pkgs; [
      go
      golangci-lint
      delve
      gopls
      go-tools
      gotools
      gotestsum
    ];
    json = with pkgs; [ nodePackages_latest.vscode-json-languageserver ];
    lua = with pkgs; [
      stylua
      luajitPackages.luacheck
      lua-language-server
    ];
    markdown = with pkgs; [
      marksman
      markdownlint-cli2
      harper
    ];
    nix = with pkgs; [
      nixd
      nixfmt-rfc-style
      statix
      nix-doc
    ];
    python = with pkgs; [
      isort
      black
      pyright
    ];
    sql = with pkgs; [
      sqls
      sqlfluff
    ];
    terraform = with pkgs; [
      terraform
      terraform-lsp
      tflint
      tfsec
    ];
    toml = with pkgs; [ taplo ];
    templ = with pkgs; [ templ ];
    typescript = with pkgs; [
      typescript-language-server
      eslint
    ];
    yaml = with pkgs; [
      yamlfmt
      yamllint
      yaml-language-server
    ];
  };
}
