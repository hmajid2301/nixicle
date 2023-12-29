{pkgs, ...}: {
  programs.bottom = {
    enable = true;
    settings = {
      colors = {
        table_header_color = "#f5e0dc";
        all_cpu_color = "#f5e0dc";
        avg_cpu_color = "#eba0ac";
        cpu_core_colors = ["#f38ba8" "#fab387" "#f9e2af" "#a6e3a1" "#74c7ec" "#cba6f7"];
        ram_color = "#a6e3a1";
        swap_color = "#fab387";
        rx_color = "#a6e3a1";
        tx_color = "#f38ba8";
        widget_title_color = "#f2cdcd";
        border_color = "#585b70";
        highlighted_border_color = "#f5c2e7";
        text_color = "#cdd6f4";
        graph_color = "#a6adc8";
        cursor_color = "#f5c2e7";
        selected_text_color = "#11111b";
        selected_bg_color = "#cba6f7";
        high_battery_color = "#a6e3a1";
        medium_battery_color = "#f9e2af";
        low_battery_color = "#f38ba8";
        gpu_core_colors = ["#74c7ec" "#cba6f7" "#f38ba8" "#fab387" "#f9e2af" "#a6e3a1"];
        arc_color = "#89dceb";
      };
    };
  };
}
