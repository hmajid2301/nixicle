{
  security = {
    protectKernelImage = false;
    tpm2 = {
      enable = true;
      pkcs11.enable = true;
      tctiEnvironment.enable = true;
    };
  };
}
