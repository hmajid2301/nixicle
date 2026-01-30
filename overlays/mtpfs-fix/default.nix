inputs: final: prev: {
  # TODO: Remove this overlay once https://github.com/NixOS/nixpkgs/pull/481778 is merged
  # This uses the upstream fix for GCC 14/15 compatibility instead of suppressing warnings
  mtpfs = prev.mtpfs.overrideAttrs (old: {
    version = "0-unstable-2024-12-10";

    src = prev.fetchFromGitHub {
      owner = "cjd";
      repo = "mtpfs";
      rev = "1177d6cfd8916915f5db7d9b5c6fc9e6eafae6e6";
      hash = "sha256-/84C8FUW+7U7u7yOzVB6ROoIUKtyIBG0wdD5t53yays=";
    };

    nativeBuildInputs = (old.nativeBuildInputs or []) ++ [ prev.autoreconfHook ];
  });
}
