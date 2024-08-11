{inputs, ...}: final: prev: {
  hyprpanel = inputs.hyprpanel.packages.${prev.system}.default;
}
