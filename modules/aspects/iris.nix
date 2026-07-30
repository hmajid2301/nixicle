{ inputs, ... }:
# IRIS — Fig-style terminal autocomplete assistant.
#
# Unlike a normal shell plugin, IRIS is a PTY *wrapper*: you launch `iris`
# (abbr `i`) to spawn a fish session with an inline suggestion overlay. Keeping
# your regular login shell as plain `fish` means full-screen TUIs (vim, fzf,
# helix, lazygit, …) run un-wrapped and untouched; `i` is opt-in for
# autocomplete sessions.
#
# We deliberately do NOT run `iris setup` from Nix: it mutates
# `~/.config/fish/config.fish` and would fight Home Manager. Nix owns the
# binary, the `i` abbr, and `~/.config/iris/config.toml`.
{
  flake-file.inputs.iris = {
    url = "github:versenilvis/iris";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  den.aspects.iris = {
    nixos =
      { inputs, ... }:
      {
        nixpkgs.overlays = [
          (_final: prev: {
            iris = inputs.iris.packages.${prev.stdenv.hostPlatform.system}.default;
          })
        ];
      };

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.iris ];

        # `i` launches a PTY-wrapped fish with the iris overlay.
        # Plain `fish` stays clean for TUIs. Do NOT run `iris setup`.
        programs.fish.shellAbbrs.i = "iris";

        xdg.configFile."iris/config.toml".text = ''
          [core]
          version = 1
          shell = "fish"      # force fish; empty would auto-detect
          mode = "last"       # "last" | "spec" | "history"
          debug = false

          [ui]
          style = "modern"    # "modern" | "classic"
          ghost-text = true
          max-suggestions = 100
          max-height = 15
          nerd-fonts = true

          [git]
          filter-active-branch = true
          deduplicate-branches = true

          # Nix owns the binary; never self-update.
          [updater]
          check-on-startup = false
          channel = "stable"

          # AI completion via local ollama (aspect `ollama` must be included
          # on the host, which binds 127.0.0.1:11434).
          [ai]
          enabled = true
          provider = "ollama"
          debounce_ms = 400

          [ai.providers.ollama]
          endpoint = "http://localhost:11434/v1/chat/completions"
          model = "qwen2.5-coder"
          timeout_ms = 5000
        '';
      };
  };
}