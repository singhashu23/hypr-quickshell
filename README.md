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
reference/    old-quickshell/ — the previous QML, kept for reference
```

## Quickshell

A fresh shell targeting **Hyprland**, replacing waybar + rofi + dunst.
Built against Quickshell 0.3.1 / Hyprland 0.56.2.

```
config/quickshell/
  shell.qml              one Bar per connected screen, via Variants
  Theme.qml              singleton: palette (Catppuccin Mocha), metrics, fonts
  modules/bar/
    Bar.qml              PanelWindow — left / center / right layout
    Pill.qml             shared rounded container (hover, click, scroll)
    IconLabel.qml        shared icon + text pair
    Workspaces.qml       Hyprland workspaces, click to switch
    ActiveWindow.qml     focused window title (via ToplevelManager)
    MediaPlayer.qml      MPRIS — click to play/pause
    Tray.qml             StatusNotifierItem tray
    Backlight.qml        brightnessctl, scroll to adjust
    Audio.qml            Pipewire — click to mute, scroll for volume
    Network.qml          nmcli — SSID and signal
    Battery.qml          UPower
    Clock.qml            click to toggle seconds
```

Run it:

```sh
qs -p ~/.config/quickshell        # foreground, logs to stdout
qs -p ~/.config/quickshell -d     # daemonized
```

To start it with the session, in `hyprland.conf`:

```
exec-once = qs -p ~/.config/quickshell
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

# configs
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

Still to build in Quickshell: launcher, notification daemon, dashboard,
power menu, and a lock screen.
