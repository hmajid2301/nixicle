from libqtile.config import DropDown, Group, Key, Match, ScratchPad
from libqtile.lazy import lazy

from modules.constants import mod, terminal
from modules.keys import keys


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
            DropDown("calendar", f"{terminal} -t calcurse -e calcurse", x=0.6785, width=0.32, height=0.997, opacity=1),
            DropDown("top", f"{terminal} -t btop -e btop", y=0.3),
            DropDown("file", f"{terminal} -t ranger -e ranger", y=0.3),
            DropDown("clock", f"{terminal} -t tty-clock -tty -e tty-clock", y=0.3),
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
