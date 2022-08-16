import os
from typing import List, Optional

from libqtile import bar, qtile
from libqtile.lazy import lazy
from qtile_extras import widget
from qtile_extras.widget.decorations import RectDecoration

from modules.constants import terminal, colors


def icon_decoration(
    color: List[str], padding_x: Optional[int] = None, padding_y: Optional[int] = 4
) -> list[RectDecoration]:
    return [
        RectDecoration(
            colour=color,
            radius=4,
            filled=True,
            padding_x=padding_x,
            padding_y=padding_y,
        )
    ]


def text_decoration() -> list[RectDecoration]:
    return [
        RectDecoration(
            colour=colors[12],
            radius=4,
            filled=True,
            padding_y=4,
            padding_x=0,
        )
    ]


def parse_window_name(text: str) -> str:
    """Simplifies the names of a few windows, to be displayed in the bar"""
    target_names = ["Mozilla Firefox", "Visual Studio Code", "Discord"]
    return next(filter(lambda name: name in text, target_names), text)


widget_list = [
    widget.TextBox(
        text="",
        foreground=colors[0],
        background=colors[9],
        mouse_callbacks={"Button1": lambda: qtile.cmd_spawn("rofi -show drun")},
        filename="~/.config/qtile/icons/arch.png",
        fontsize=30,
        padding=15,
        decorations=icon_decoration(colors[9]),
    ),
    widget.Sep(linewidth=0, padding=6, foreground=colors[2], background=colors[0]),
    widget.GroupBox(
        fontsize=30,
        margin_y=3,
        margin_x=5,
        padding_y=5,
        padding_x=5,
        borderwidth=3,
        active=colors[8],
        inactive=colors[7],
        rounded=True,
        highlight_color=colors[2],
        highlight_method="line",
        this_current_screen_border=colors[8],
        this_screen_border=colors[8],
        background=colors[0],
    ),
    widget.Sep(
        linewidth=0,
        padding=10,
        size_percent=40,
    ),
    widget.CurrentLayoutIcon(
        custom_icon_paths=[os.path.expanduser("~/.config/qtile/icons")],
        background=colors[0],
        scale=0.60,
    ),
    widget.Spacer(),
    widget.TextBox(
        text="",
        foreground=colors[0],
        fontsize=24,
        padding=8,
        decorations=icon_decoration(colors[1]),
    ),
    widget.WindowName(
        for_current_screen=True,
        fmt="{}",
        empty_group_string="Desktop",
        max_chars=120,
        width=bar.CALCULATED,
        foreground=colors[1],
        padding=15,
        decorations=text_decoration(),
        parse_text=parse_window_name,
    ),
    widget.Spacer(),
    widget.Sep(
        linewidth=0,
        padding=20,
    ),
    widget.CheckUpdates(
        distro="Arch_yay",
        foreground=colors[0],
        display_format="Updates: {updates}",
        mouse_callbacks={"Button1": lambda: qtile.cmd_spawn(f"{terminal} -e yay -Syu")},
        padding=15,
        decorations=text_decoration(),
    ),
    widget.Sep(
        linewidth=0,
        padding=20,
    ),
    widget.TextBox(
        text="",
        foreground=colors[0],
        fontsize=24,
        padding=8,
        decorations=icon_decoration(colors[8]),
    ),
    widget.ThermalSensor(
        tag_sensor="Tctl",
        threshold=90,
        fmt="{}",
        padding=15,
        foreground_alert=colors[3],
        foreground=colors[8],
        decorations=text_decoration(),
        mouse_callbacks={"Button1": lambda: qtile.cmd_spawn("psensor")},
    ),
    widget.Sep(
        width=10,
        foreground=colors[12],
    ),
    widget.TextBox(
        text="墳",
        foreground=colors[10],
        fontsize=20,
        padding=8,
        decorations=icon_decoration(colors[6]),
    ),
    widget.Volume(
        foreground=colors[6],
        limit_max_volume="True",
        fmt="{}",
        padding=8,
        decorations=text_decoration(),
        mouse_callbacks={"Button1": lambda: qtile.cmd_spawn("pavucontrol")},
    ),
    widget.Sep(
        width=30,
        foreground=colors[12],
    ),
    widget.TextBox(
        text="",
        foreground=colors[0],
        decorations=icon_decoration(colors[4]),
        fontsize=20,
        padding=8,
    ),
    widget.Clock(
        format="%a, %b %d",
        foreground=colors[4],
        decorations=text_decoration(),
        padding=8,
        mouse_callbacks={"Button1": lazy.group["scratchpad"].dropdown_toggle("calendar")},
    ),
    widget.Sep(
        width=20,
        foreground=colors[12],
    ),
    widget.TextBox(
        text="",
        foreground=colors[0],
        decorations=icon_decoration(colors[3]),
        fontsize=20,
        padding=8,
    ),
    widget.Clock(
        format="%H:%M:%S",
        foreground=colors[3],
        padding=15,
        decorations=text_decoration(),
        mouse_callbacks={"Button1": lazy.group["scratchpad"].dropdown_toggle("clock")},
    ),
    widget.Sep(
        width=30,
        foreground=colors[12],
    ),
    widget.TextBox(
        text="",
        foreground=colors[0],
        fontsize=18,
        padding=20,
        mouse_callbacks={
            "Button1": lazy.spawn(os.path.expanduser("~/.config/rofi/powermenu/powermenu.sh")),
        },
        decorations=icon_decoration(colors[9]),
    ),
    widget.KeyboardLayout(configured_keyboards=["gb"], fmt=""),
]
