# Copyright (c) 2010 Aldo Cortesi
# Copyright (c) 2010, 2014 dequis
# Copyright (c) 2012 Randall Ma
# Copyright (c) 2012-2014 Tycho Andersen
# Copyright (c) 2012 Craig Barnes
# Copyright (c) 2013 horsik
# Copyright (c) 2013 Tao Sauvage
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

import os

from libqtile import bar, layout, qtile
from libqtile.config import Click, Drag, DropDown, Group, Key, Match, ScratchPad, Screen
from libqtile.lazy import lazy
from qtile_extras import widget
from qtile_extras.widget.decorations import RectDecoration

mod = "mod4"
terminal = "alacritty"

colors = [
    ["#1E1E2E", "#1E1E2E"],  # 0 black
    ["#D9E0EE", "#D9E0EE"],  # 1 light grey
    ["#45475a", "#45475a"],  # 2 grey
    ["#F28FAD", "#F28FAD"],  # 3 pink
    ["#ABE9B3", "#ABE9B3"],  # 4 green
    ["#FAE3B0", "#FAE3B0"],  # 5 orange
    ["#96CDFB", "#96CDFB"],  # 6 light blue
    ["#988BA2", "#988BA2"],  # 7 browny grey
    ["#DDB6F2", "#DDB6F2"],  # 8 purply pink
    ["#F5C2E7", "#F5C2E7"],  # 9 light pink
    ["#262626", "#262626"],  # 10 background
    ["#FFFFD4", "#FFFFD4"],  # 11 foreground
    ["#302D41", "#302D41"],  # 12 black 3
]


keys = [
    # A list of available commands that can be bound to keys can be found
    # at https://docs.qtile.org/en/latest/manual/config/lazy.html
    # Switch between windows
    Key([mod], "h", lazy.layout.left(), desc="Move focus to left"),
    Key([mod], "l", lazy.layout.right(), desc="Move focus to right"),
    Key([mod], "j", lazy.layout.down(), desc="Move focus down"),
    Key([mod], "k", lazy.layout.up(), desc="Move focus up"),
    Key([mod], "space", lazy.layout.next(), desc="Move window focus to other window"),
    # Move windows between left/right columns or move up/down in current stack.
    # Moving out of range in Columns layout will create new column.
    Key([mod, "shift"], "h", lazy.layout.shuffle_left(), desc="Move window to the left"),
    Key([mod, "shift"], "l", lazy.layout.shuffle_right(), desc="Move window to the right"),
    Key([mod, "shift"], "j", lazy.layout.shuffle_down(), desc="Move window down"),
    Key([mod, "shift"], "k", lazy.layout.shuffle_up(), desc="Move window up"),
    # Grow windows. If current window is on the edge of screen and direction
    # will be to screen edge - window would shrink.
    Key([mod, "control"], "h", lazy.layout.grow_left(), desc="Grow window to the left"),
    Key([mod, "control"], "l", lazy.layout.grow_right(), desc="Grow window to the right"),
    Key([mod, "control"], "j", lazy.layout.grow_down(), desc="Grow window down"),
    Key([mod, "control"], "k", lazy.layout.grow_up(), desc="Grow window up"),
    Key([mod], "n", lazy.layout.normalize(), desc="Reset all window sizes"),
    # Toggle between split and unsplit sides of stack.
    # Split = all windows displayed
    # Unsplit = 1 window displayed, like Max layout, but still with
    # multiple stack panes
    Key(
        [mod, "shift"],
        "Return",
        lazy.layout.toggle_split(),
        desc="Toggle between split and unsplit sides of stack",
    ),
    Key([mod], "Return", lazy.spawn(terminal), desc="Launch terminal"),
    # Toggle between different layouts as defined below
    Key([mod], "Tab", lazy.next_layout(), desc="Toggle between layouts"),
    Key([mod], "w", lazy.window.kill(), desc="Kill focused window"),
    Key([mod, "control"], "r", lazy.reload_config(), desc="Reload the config"),
    Key([mod, "control"], "q", lazy.shutdown(), desc="Shutdown Qtile"),
    Key([mod], "r", lazy.spawn("rofi -show drun"), desc="Launch selected application"),
    # Sound
    Key([], "XF86AudioMute", lazy.spawn(os.path.expanduser("~/.config/qtile/volume.sh mute"))),
    Key([], "XF86AudioLowerVolume", lazy.spawn(os.path.expanduser("~/.config/qtile/volume.sh down"))),
    Key([], "XF86AudioRaiseVolume", lazy.spawn(os.path.expanduser("~/.config/qtile/volume.sh up"))),
    Key([], "XF86AudioNext", lazy.spawn("playerctl next")),
    Key([], "XF86AudioPrev", lazy.spawn("playerctl previous")),
    Key([], "XF86AudioPlay", lazy.spawn("playerctl play-pause")),
    Key([], "XF86AudioStop", lazy.spawn("playerctl play-pause")),
    # Other
    Key([], "Print", lazy.spawn("flameshot gui"), desc="Take screenshot"),
    Key([mod], "Escape", lazy.spawn("dm-tool switch-to-greeter"), desc="Look screen by opening LightDM"),
    Key(
        ["mod1", "control"],
        "Delete",
        lazy.spawn(os.path.expanduser("~/.config/rofi/powermenu/powermenu.sh")),
        desc="Show power menu",
    ),
]


# groups = [Group(i) for i in "12345"]

# for i in groups:
#     keys.extend(
#         [
#             # mod1 + letter of group = switch to group
#             Key(
#                 [mod],
#                 i.name,
#                 lazy.group[i.name].toscreen(),
#                 desc="Switch to group {}".format(i.name),
#             ),
#             # mod1 + shift + letter of group = switch to & move focused window to group
#             Key(
#                 [mod, "shift"],
#                 i.name,
#                 lazy.window.togroup(i.name, switch_group=True),
#                 desc="Switch to & move focused window to group {}".format(i.name),
#             ),
#             # Or, use below if you prefer not to switch to that group.
#             # # mod1 + shift + letter of group = move focused window to group
#             # Key([mod, "shift"], i.name, lazy.window.togroup(i.name),
#             #     desc="move focused window to group {}".format(i.name)),
#         ]
#     )


workspaces = [
    {
        "name": "",
        "key": "1",
        "lay": "bsp",
    },
    {"name": "", "key": "2", "matches": [Match(wm_class="firefox")], "lay": "bsp"},
    {
        "name": "",
        "key": "3",
        "lay": "max",
    },
]

groups = [
    ScratchPad(
        "scratchpad",
        [
            # define a drop down terminal.
            DropDown(
                "term",
                "alacritty --class dropdown -e tmux new -As Dropdown",
                height=0.6,
                on_focus_lost_hide=False,
                opacity=1,
                warp_pointer=False,
            ),
        ],
    ),
    ScratchPad(
        "scratchpad",
        [
            DropDown("khal", terminal + " -t ikhal -e ikhal", x=0.6785, width=0.32, height=0.997, opacity=1),
        ],
    ),
]

for workspace in workspaces:
    matches = workspace["matches"] if "matches" in workspace else None
    groups.append(Group(workspace["name"], matches=matches, layout=workspace["lay"]))  # type:ignore
    keys.append(
        Key(
            [mod],
            workspace["key"],
            lazy.group[workspace["name"]].toscreen(toggle=True),
            desc="Focus this desktop",
        )
    )
    keys.append(
        Key(
            [mod, "shift"],
            workspace["key"],
            lazy.window.togroup(workspace["name"]),
            desc="Move focused window to another group",
        )
    )


def window_to_previous_screen(qtile, switch_group=False, switch_screen=False):
    i = qtile.screens.index(qtile.current_screen)
    if i != 0:
        group = qtile.screens[i - 1].group.name
        qtile.current_window.togroup(group, switch_group=switch_group)
        if switch_screen == True:
            qtile.cmd_to_screen(i - 1)


def window_to_next_screen(qtile, switch_group=False, switch_screen=False):
    i = qtile.screens.index(qtile.current_screen)
    if i + 1 != len(qtile.screens):
        group = qtile.screens[i + 1].group.name
        qtile.current_window.togroup(group, switch_group=switch_group)
        if switch_screen == True:
            qtile.cmd_to_screen(i + 1)


keys.extend(
    [
        Key([mod, "shift"], "comma", lazy.function(window_to_next_screen)),
        Key([mod, "shift"], "period", lazy.function(window_to_previous_screen)),
        Key([mod, "control"], "comma", lazy.function(window_to_next_screen, switch_screen=True)),
        Key([mod, "control"], "period", lazy.function(window_to_previous_screen, switch_screen=True)),
        Key([mod], "comma", lazy.next_screen(), desc="Next monitor"),
        Key([mod], "period", lazy.prev_screen(), desc="Prev monitor"),
    ]
)

layout_theme = {
    "border_width": 2,
    "margin": 4,
    "border_focus": colors[8],
    "border_normal": colors[12],
    "grow_amount": 1,
}

layouts = [
    layout.Bsp(**layout_theme),  # type: ignore
    layout.MonadTall(**layout_theme),  # type: ignore
    layout.Max(),  # type: ignore
    layout.Columns(**layout_theme),  # type: ignore
    # Try more layouts by unleashing below layouts.
    # layout.Stack(num_stacks=2),
    # layout.Bsp(),
    # layout.Matrix(),
    # layout.MonadWide(),
    # layout.RatioTile(),
    # layout.Tile(),
    # layout.TreeTab(),
    # layout.VerticalTile(),
    # layout.Zoomy(),
]


widget_defaults = dict(
    font="Mono Lisa Bold",
    fontsize=18,
    padding=3,
    background=colors[0],
)
extension_defaults = widget_defaults.copy()


def text_decoration(color, padding_x=None, padding_y=4):
    return [
        RectDecoration(
            colour=color,
            radius=4,
            filled=True,
            padding_x=padding_x,
            padding_y=padding_y,
        )
    ]


def icon_decoration():
    return [
        RectDecoration(
            colour=colors[12],
            radius=4,
            filled=True,
            padding_y=4,
            padding_x=0,
        )
    ]


def parse_window_name(text):
    """Simplifies the names of a few windows, to be displayed in the bar"""
    target_names = [
        "Mozilla Firefox",
        "Visual Studio Code",
        "Discord",
    ]
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
        decorations=text_decoration(colors[9]),
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
        decorations=text_decoration(colors[1]),
    ),
    widget.WindowName(
        for_current_screen=True,
        fmt="{}",
        empty_group_string="Desktop",
        max_chars=120,
        width=bar.CALCULATED,
        foreground=colors[1],
        padding=15,
        decorations=icon_decoration(),
        parse_text=parse_window_name,
    ),
    widget.Spacer(),
    widget.Systray(icon_size=24, padding=7),
    widget.Sep(
        linewidth=0,
        padding=20,
    ),
    widget.CheckUpdates(
        distro="Arch_yay",
        foreground=colors[0],
        background=colors[2],
        display_format=" Updates: {updates}",
        mouse_callbacks={"Button1": lambda: qtile.cmd_spawn(f"{terminal} -e yay")},
        padding=5,
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
        decorations=text_decoration(colors[8]),
    ),
    widget.ThermalSensor(
        tag_sensor="Tctl",
        threshold=90,
        fmt="{}",
        padding=15,
        foreground_alert=colors[3],
        foreground=colors[8],
        decorations=icon_decoration(),
        mouse_callbacks={"Button2": lambda: qtile.cmd_spawn("psensor")},
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
        decorations=text_decoration(colors[6]),
    ),
    widget.Volume(
        foreground=colors[6],
        limit_max_volume="True",
        fmt="{}",
        padding=8,
        decorations=icon_decoration(),
        mouse_callbacks={"Button2": lambda: qtile.cmd_spawn("pavucontrol")},
    ),
    widget.Sep(
        width=30,
        foreground=colors[12],
    ),
    widget.TextBox(
        text="",
        foreground=colors[0],
        decorations=text_decoration(colors[4]),
        fontsize=20,
        padding=8,
    ),
    widget.Clock(
        format="%a, %b %d",
        foreground=colors[4],
        decorations=icon_decoration(),
        padding=8,
        mouse_callbacks={"Button1": lazy.group["scratchpad"].dropdown_toggle("khal")},
    ),
    widget.Sep(
        width=20,
        foreground=colors[12],
    ),
    widget.TextBox(
        text="",
        foreground=colors[0],
        decorations=text_decoration(colors[3]),
        fontsize=20,
        padding=8,
    ),
    widget.Clock(
        format="%H:%M:%S",
        foreground=colors[3],
        padding=15,
        decorations=icon_decoration(),
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
        decorations=text_decoration(colors[9]),
    ),
    widget.KeyboardLayout(configured_keyboards=["gb"], fmt=""),
]

screens = [
    Screen(
        top=bar.Bar(
            widgets=widget_list,
            size=40,
            background="#1A1826",
            border_width=[0, 0, 0, 0],
        ),
    ),
]

# Drag floating layouts.
mouse = [
    Drag([mod], "Button1", lazy.window.set_position_floating(), start=lazy.window.get_position()),
    Drag([mod], "Button3", lazy.window.set_size_floating(), start=lazy.window.get_size()),
    Click([mod], "Button2", lazy.window.bring_to_front()),
]

dgroups_key_binder = None
dgroups_app_rules = []  # type: list
follow_mouse_focus = True
bring_front_click = False
cursor_warp = False
floating_layout = layout.Floating(  # type: ignore
    float_rules=[
        # Run the utility of `xprop` to see the wm class and name of an X client.
        *layout.Floating.default_float_rules,  # type: ignore
        Match(wm_class="confirmreset"),  # gitk
        Match(wm_class="makebranch"),  # gitk
        Match(wm_class="maketag"),  # gitk
        Match(wm_class="ssh-askpass"),  # ssh-askpass
        Match(title="branchdialog"),  # gitk
        Match(title="pinentry"),  # GPG key password entry
    ]
)
auto_fullscreen = True
focus_on_window_activation = "smart"
reconfigure_screens = True

# If things like steam games want to auto-minimize themselves when losing
# focus, should we respect this or not?
auto_minimize = True

# When using the Wayland backend, this can be used to configure input devices.
wl_input_rules = None

# XXX: Gasp! We're lying here. In fact, nobody really uses or cares about this
# string besides java UI toolkits; you can see several discussions on the
# mailing lists, GitHub issues, and other WM documentation that suggest setting
# this string if your java app doesn't work correctly. We may as well just lie
# and say that we're a working one by default.
#
# We choose LG3D to maximize irony: it is a 3D non-reparenting WM written in
# java that happens to be on java's whitelist.
wmname = "LG3D"
