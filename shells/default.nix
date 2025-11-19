{pkgs, inputs}:
{
  default = import ./default {
    inherit pkgs inputs;
  };
}
