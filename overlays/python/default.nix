final: prev: {
  pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
    (python-final: python-prev: {
      # Workaround for bug #437058
      i3ipc = python-prev.i3ipc.overridePythonAttrs (oldAttrs: {
        doCheck = false;
        checkPhase = ''
          echo "Skipping pytest in Nix build"
        '';
        installCheckPhase = ''
          echo "Skipping install checks in Nix build"
        '';
      });
    })
  ];
}
