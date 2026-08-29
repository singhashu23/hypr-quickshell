# hyprland-waybar-setup

Snapshot of my Linux desktop configuration — Hyprland/Wayland configs, helper
scripts, and wallpaper collections. Archived here as the starting point for a
rebuild of the setup around [Quickshell](https://quickshell.org/).

## Layout

```
config/       ~/.config/<name>  — drop-in replacements
  hypr/         Hyprland compositor + hyprpaper
  waybar/       status bar (current)
  quickshell/   the new Quickshell shell (see below)
  ags/          older Astal/AGS bar attempt
  rofi/ wofi/ fuzzel/    launchers
  dunst/ swaync/         notification daemons
  kitty/ ghostty/ foot/  terminals
  wlogout/      logout menu
bin/          ~/.local/bin — helper scripts (see below)
config/wal/   pywal templates
wallpapers/   wall, wall_1, wall_3, wall_4
```

## Quickshell

A fresh shell targeting **Hyprland**, replacing waybar + rofi + dunst.
Built against Quickshell 0.3.1 / Hyprland 0.56.2.

Two shells live side by side as *named* configs. Neither is the default, so
neither can shadow the other:

```
config/quickshell/
  hyprland/   the new island shell   ->  qs -c hyprland
  niri/       the previous shell     ->  qs -c niri
```

There must be no `shell.qml` directly under `config/quickshell/` — Quickshell
would register it as the 'default' config and stop scanning subdirectories
entirely.

```
config/quickshell/hyprland/
  shell.qml              one Bar per screen + one Launcher
  Theme.qml              design tokens: colour, metrics, type, motion
  services/
    Pywal.qml            live ~/.cache/wal/colors.json
    Gtk.qml              the desktop's GTK theme, icon theme and font
    Apps.qml             desktop-entry index + ranked search
    Compositor.qml       workspaces, over Hyprland or niri
  scripts/apps.py        .desktop scanner; resolves icons via the GTK theme
  modules/bar/
    Bar.qml              transparent panel holding three islands
    Island.qml           the rounded slab itself
    Pill.qml             an item inside an island (hover, click, scroll)
    IconLabel.qml        icon + text pair
    Workspaces.qml       click to switch
    ActiveWindow.qml     focused window title (ToplevelManager)
    MediaPlayer.qml      MPRIS — click to play/pause
    Tray.qml             StatusNotifierItem tray
    Backlight.qml        brightnessctl, scroll to adjust
    Audio.qml            Pipewire — click to mute, scroll for volume
    Network.qml          nmcli — SSID and signal
    Battery.qml          UPower
    Clock.qml            click to toggle seconds
  modules/launcher/
    Launcher.qml         wallpaper tile + three tabs: apps, open windows, calculator
  modules/notifications/
    Notifications.qml    org.freedesktop.Notifications daemon + toast stack
    NotificationCard.qml a single toast, shaped like every other island
```

### Launcher

One island, three tabs — the same three the niri launcher carries:

| tab | what it lists | activating a row |
|---|---|---|
| **Apps** | desktop entries, ranked so a prefix beats a mid-string hit | launches it |
| **Windows** | what is already open, with each window's own icon | focuses it |
| **Calculator** | a keypad over the search field | folds the result back into the expression |

`Tab` / `Shift+Tab` or `←` / `→` move between tabs; `Up`/`Down` move within a
list; `Enter` activates. Left and right therefore do not move the text caret —
`Home`/`End` and the mouse still do. Each tab can also be opened directly over
IPC, for a keybind of its own:

```sh
qs -c hyprland ipc call launcher windows
qs -c hyprland ipc call launcher calculator
```

The card is a fixed size — set by the wallpaper tile, identical on all three
tabs — so a long list scrolls inside it rather than resizing the launcher under
the cursor.

### Notifications

A full D-Bus notification daemon, so `swaync` is not needed. Toasts stack under
the bar on one screen — duplicating a toast across monitors is noise, not
redundancy.

- **Critical notifications never auto-expire.** Silently expiring the one that
  mattered is the failure mode worth designing against; everything else gets
  4s (low) or 6s (normal), or whatever the sender asks for.
- **Hovering pauses the countdown**, so reading never races the timer. A hairline
  along the bottom edge shows the remaining time.
- **Actions are rendered as buttons.** The previous daemon advertised
  `actionsSupported` but never drew them, so every actionable notification was a
  dead end.
- Notification images (album art, avatars) take precedence over the app icon;
  a missing icon falls back to a glyph.
- Click a toast to dismiss; click an action to invoke it and dismiss.

Requires `QT_QPA_PLATFORMTHEME` to be set — see below.

### Qt icon theme

`hyprland.conf` sets `env = QT_QPA_PLATFORMTHEME,qt6ct`. Without it Qt loads no
icon theme at all, and every `image://icon/…` lookup returns a magenta
placeholder *with `status === Ready`* — so it cannot even be detected and
handled in QML. That affects tray icons and notification icons alike.

Note the icon theme is configured in three places that currently disagree:
`~/.config/gtk-3.0/settings.ini` (`Flattery` — a typo, no such theme),
`gsettings` (`Flatery`), and `~/.config/qt6ct/qt6ct.conf`
(`Tela-circle-dracula`). The launcher sidesteps this by resolving icons itself
through `gsettings`.

### Design language

Follows [ryoku](https://github.com/neur0map/ryoku-arch): paper and ink — warm
bone type on pure black — with the frame retinting live from the wallpaper, and
one motion language across every surface.

That splits cleanly in `Theme.qml`. The **ground** is fixed near-black and the
**type** is a fixed warm bone, because those two carry legibility. pywal drives
the **accents, borders and highlights**, which is where wallpaper colour
actually belongs. Set `inkAndPaper: false` to tint the ground from the wallpaper
too.

Surfaces are **islands**: discrete rounded slabs with real gaps between them,
sharing one corner radius, one hairline border, and one set of durations. The
bar is three islands (workspaces / window / status); the launcher is a fourth.

### Launcher

`SUPER + space`. Empty, it shows the time and date. Typing filters applications;
an arithmetic expression is evaluated inline above the results.

- `↑` `↓` `Tab` move, `Enter` launches, `Esc` closes, click-away closes
- Ranked matching: exact > name prefix > name substring > keywords > comment > exec
- Icons resolved against the **live GTK icon theme**, not Qt's

Driven over IPC, so it can be bound from anywhere:

```sh
qs -c hyprland ipc call launcher toggle
qs -c hyprland ipc call launcher open
```

### Compositor support

`services/Compositor.qml` presents one workspace interface over two back ends.
Hyprland is the target; niri is supported because this setup is often driven
from a niri session, and a workspace widget you can only check after logging out
is a workspace widget you cannot check. Hyprland uses the `Quickshell.Hyprland`
module, niri its JSON event stream.

### GTK

`services/Gtk.qml` reads the desktop's theme, icon theme and font from
`gsettings`, so the shell matches the rest of the session:

- launcher prose uses the GTK font (`Cantarell`); the bar keeps a Nerd Font
  because the glyph icons live in it
- `scripts/apps.py` resolves every app icon through the GTK icon theme and its
  `Inherits` chain, falling back to `hicolor` and `/usr/share/pixmaps`

Qt only picks up the GTK icon theme when `QT_QPA_PLATFORMTHEME` is configured,
and it usually is not — hence resolving icons to absolute paths here rather than
handing names to Qt.

Run it:

```sh
qs -c hyprland        # foreground, logs to stdout
qs -c hyprland -d     # daemonized
qs -c niri            # the previous shell, unchanged
```

To start it with the session, in `hyprland.conf`:

```
exec-once = qs -c hyprland
```

Notes:
- Modules degrade instead of erroring: `Workspaces` is empty off Hyprland,
  `Battery` hides without one, `MediaPlayer` and `Tray` hide when empty.
- `Theme.qml` is the single place to retheme.

## pywal

The whole desktop follows the wallpaper's palette.

`randWall` picks a wallpaper, sets it with `awww`, and runs `wal`, which
regenerates `~/.cache/wal/`. From there two consumers pick it up:

**Quickshell** — `services/Pywal.qml` reads `~/.cache/wal/colors.json` through a
`FileView` with `watchChanges: true`, so the bar retints the instant pywal
rewrites the file. No restart, no signal, no reload command.

**Hyprland** — `config/wal/templates/colors-hyprland.conf` makes pywal emit
`~/.cache/wal/colors-hyprland.conf` in Hyprland syntax (`$color0` … `$color15`).
`hyprland.conf` sources it and uses `$color4`/`$color6` for the active border.
Hyprland can't watch the file, so `randWall` calls `hyprctl reload`.

Install the template (pywal only reads templates from `~/.config/wal/templates`):

```sh
mkdir -p ~/.config/wal/templates
cp config/wal/templates/colors-hyprland.conf ~/.config/wal/templates/
```

Theming controls in `Theme.qml`:

| property | default | effect |
| --- | --- | --- |
| `usePywal` | `true` | derive backgrounds, text and accents from the wallpaper; `false` pins the built-in Catppuccin Mocha |
| `pywalStatusColors` | `false` | also tint low-battery / offline red, charging green, etc. Off by default — pywal palettes are often near-monochrome, and a warning tinted to match the wallpaper stops reading as a warning |

If `~/.cache/wal/colors.json` is missing, the shell falls back to Catppuccin
rather than failing.

## Install

```sh
git clone <this-repo> ~/hyprland-waybar-setup
cd ~/hyprland-waybar-setup

# configs (quickshell included — it carries both named configs)
for d in config/*/; do ln -sfn "$PWD/$d" ~/.config/"$(basename "$d")"; done

# scripts
mkdir -p ~/.local/bin
cp bin/* ~/.local/bin/ && chmod +x ~/.local/bin/*

# wallpapers (scripts expect ~/Pictures/wall)
mkdir -p ~/Pictures
cp -r wallpapers/* ~/Pictures/
```

## Scripts in `bin/`

| Script | Purpose |
| --- | --- |
| `randWall`, `initRandomWallpaper` | pick a random wallpaper from `~/Pictures/wall`, apply via `swww`, regenerate pywal colors, restart waybar |
| `changeWallpaper`, `randomWallpaper`, `randomNatureWallpaper` | X11-era variants using `xwallpaper` |
| `niriChangeWall`, `niriWallpaperinit` | niri-session wallpaper handling |
| `wallAddress` | print the wallpaper currently loaded by `swaybg` |
| `powermenu`, `power-menu.sh`, `bsppowermenu` | rofi power menus |
| `network_menu`, `wifi` | NetworkManager picker via rofi / `nmcli` |
| `volume`, `music`, `battery`, `clock`, `nettraf` | status-bar data sources |
| `screenshot`, `rofiimg` | capture + image picker |
| `idleLock`, `lock.sh`, `waylandLockscreen` | idle and lock handling |
| `alacrittyColors.sh`, `wal` | pywal → terminal color plumbing |
| `bspthemes`, `autostart_bspwm.sh`, `.xinitrc` | leftovers from the bspwm setup |

Binaries that lived alongside these (`eww`, `st`, `goose`, `kiro-cli*`) are
deliberately excluded — they are build outputs, not configuration.

## Known rough edges

- `config/hypr/hyprpaper.conf` still points at `/home/ashu/Pictures/1.jpg` — a
  stale username from an older install. It is unused (wallpapers go through
  `awww`), so it can probably just be deleted.
- `monitor=DP-4` in `hyprland.conf` does not match this machine's outputs,
  which are `DP-1` and `eDP-1`.
- `config/hypr/` carries four generations of config (`hyprland.conf` plus
  `hyprland1/2/3.conf`); only `hyprland.conf` is live.
- `randWall` called `alacrittyColosrs.sh`, which does not exist (the script is
  `alacrittyColors.sh`) — fixed.
- The machine is presently running **niri**, not Hyprland.

## Next

Still to build in Quickshell: dashboard, control sidebar, power menu, and a
lock screen.
