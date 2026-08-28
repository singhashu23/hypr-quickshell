# hyprland-waybar-setup

Snapshot of my Linux desktop configuration — Hyprland/Wayland configs, helper
scripts, and wallpaper collections. Archived here as the starting point for a
rebuild of the setup around [Quickshell](https://quickshell.org/).

## Layout

```
config/       ~/.config/<name>  — drop-in replacements
  hypr/         Hyprland compositor + hyprpaper
  waybar/       status bar (current)
  quickshell/   QML shell components (bar, launcher, dashboard, powermenu, wifi)
  ags/          older Astal/AGS bar attempt
  rofi/ wofi/ fuzzel/    launchers
  dunst/ swaync/         notification daemons
  kitty/ ghostty/ foot/  terminals
  wlogout/      logout menu
bin/          ~/.local/bin — helper scripts (see below)
wallpapers/   wall, wall_1, wall_3, wall_4
```

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
  stale username from an older install. Fix the path before use.
- `config/hypr/` carries four generations of config (`hyprland.conf` plus
  `hyprland1/2/3.conf`); only `hyprland.conf` is live.
- Wallpaper scripts call `awww` (a typo for `swww`) and `alacrittyColosrs.sh`
  (typo for `alacrittyColors.sh`), so they currently fail silently.
- The machine is presently running **niri**, not Hyprland.

## Next

Rebuild the shell in Quickshell — bar, launcher, notifications, dashboard,
power menu — replacing waybar + rofi + dunst.
