{pkgs, ...}: {
  programs.bottom = {
    enable = true;
    settings = {
      colors = {
        table_header_color = "#f2d5cf";
        all_cpu_color = "#f2d5cf";
        avg_cpu_color = "#ea999c";
        cpu_core_colors = ["#e78284" "#ef9f76" "#e5c890" "#a6d189" "#85c1dc" "#ca9ee6"];
        ram_color = "#a6d189";
        swap_color = "#ef9f76";
        rx_color = "#a6d189";
        tx_color = "#e78284";
        widget_title_color = "#eebebe";
        border_color = "#626880";
        highlighted_border_color = "#f4b8e4";
        text_color = "#c6d0f5";
        graph_color = "#a5adce";
        cursor_color = "#f4b8e4";
        selected_text_color = "#232634";
        selected_bg_color = "#ca9ee6";
        high_battery_color = "#a6d189";
        medium_battery_color = "#e5c890";
        low_battery_color = "#e78284";
        gpu_core_colors = ["#85c1dc" "#ca9ee6" "#e78284" "#ef9f76" "#e5c890" "#a6d189"];
        arc_color = "#99d1db";
      };
    };
  };
}
