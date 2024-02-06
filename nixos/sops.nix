{inputs, ...}: {
  imports = [
    inputs.sops-nix.nixosModules.sops
  ];

  sops = {
    gnupg = {
      home = "~/.gnupg";
      sshKeyPaths = [];
    };
    age.sshKeyPaths = ["/etc/ssh/ssh_host_ed25519_key"];
  };
}
