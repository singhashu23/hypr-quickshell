#!/usr/bin/env python3
"""Scan .desktop entries and resolve each icon against the live GTK icon theme.

Emits JSON on stdout for the Quickshell launcher. Icons are resolved to
absolute paths here rather than handed to Qt as names, because Qt only picks up
the GTK icon theme when QT_QPA_PLATFORMTHEME is configured, and it usually
isn't.
"""

import configparser
import json
import os
import subprocess
import sys

HOME = os.path.expanduser("~")
ICON_DIRS = [
    os.path.join(HOME, ".local/share/icons"),
    os.path.join(HOME, ".icons"),
    "/usr/share/icons",
    "/usr/local/share/icons",
]
PIXMAPS = ["/usr/share/pixmaps"]
EXTS = (".png", ".svg", ".xpm")


def gtk_icon_theme():
    """The icon theme the desktop is actually using, most authoritative first."""
    try:
        out = subprocess.run(
            ["gsettings", "get", "org.gnome.desktop.interface", "icon-theme"],
            capture_output=True, text=True, timeout=2,
        ).stdout.strip().strip("'\"")
        if out:
            return out
    except Exception:
        pass

    ini = os.path.join(HOME, ".config/gtk-3.0/settings.ini")
    if os.path.exists(ini):
        cp = configparser.ConfigParser()
        try:
            cp.read(ini)
            return cp.get("Settings", "gtk-icon-theme-name", fallback="Adwaita")
        except Exception:
            pass
    return "Adwaita"


def theme_chain(name, seen=None):
    """A theme plus everything it Inherits, depth-first, de-duplicated."""
    if seen is None:
        seen = []
    if name in seen:
        return seen
    seen.append(name)

    for d in ICON_DIRS:
        index = os.path.join(d, name, "index.theme")
        if not os.path.exists(index):
            continue
        cp = configparser.ConfigParser(strict=False)
        try:
            cp.read(index)
            inherits = cp.get("Icon Theme", "Inherits", fallback="")
        except Exception:
            inherits = ""
        for parent in (p.strip() for p in inherits.split(",") if p.strip()):
            theme_chain(parent, seen)
        break
    return seen


def dir_size(base, dirpath):
    """Crude size signal from a path, e.g. .../48x48/..., .../apps/32/, /scalable/."""
    seg = dirpath[len(base):]
    if "scalable" in seg:
        return 512
    size = 0
    for part in seg.split(os.sep):
        if part.isdigit():                      # Flatery-style apps/32
            size = max(size, int(part))
        elif "x" in part:                       # hicolor-style 48x48
            head = part.split("x")[0]
            if head.isdigit():
                size = max(size, int(head))
    return size


def build_index(themes):
    """icon name -> best path.

    Theme order beats image size. Picking a theme is exactly a statement that
    its art should win, so an icon the chosen theme ships must outrank a bigger
    one from further down the Inherits chain — otherwise every app that ships a
    scalable icon into hicolor overrides the theme and the setting does nothing.
    Size, then vector over raster, only break ties inside one theme.
    """
    index = {}

    def consider(name, path, rank, size, vector):
        # lower rank wins; ties fall through to size and then to svg
        key = (-rank, size, vector)
        if name not in index or key > index[name][1]:
            index[name] = (path, key)

    for rank, theme in enumerate(themes):
        for root_dir in ICON_DIRS:
            base = os.path.join(root_dir, theme)
            if not os.path.isdir(base):
                continue
            for dirpath, _dirnames, filenames in os.walk(base):
                size = dir_size(base, dirpath)
                for fn in filenames:
                    if not fn.endswith(EXTS):
                        continue
                    consider(os.path.splitext(fn)[0], os.path.join(dirpath, fn),
                             rank, size, fn.endswith(".svg"))

    # loose pixmaps sit below every theme
    for p in PIXMAPS:
        if os.path.isdir(p):
            for fn in os.listdir(p):
                if fn.endswith(EXTS):
                    consider(os.path.splitext(fn)[0], os.path.join(p, fn),
                             len(themes) + 1, 0, fn.endswith(".svg"))

    return {k: v[0] for k, v in index.items()}


def desktop_dirs():
    dirs = [os.path.join(HOME, ".local/share/applications")]
    xdg = os.environ.get("XDG_DATA_DIRS", "/usr/local/share:/usr/share")
    dirs += [os.path.join(d, "applications") for d in xdg.split(":")]
    flat = os.path.join(HOME, ".local/share/flatpak/exports/share/applications")
    dirs.append(flat)
    dirs.append("/var/lib/flatpak/exports/share/applications")
    return dirs


def main():
    icons = build_index(theme_chain(gtk_icon_theme()) + ["hicolor"])
    apps = {}

    for d in desktop_dirs():
        if not os.path.isdir(d):
            continue
        for fn in sorted(os.listdir(d)):
            if not fn.endswith(".desktop"):
                continue
            cp = configparser.ConfigParser(interpolation=None, strict=False)
            try:
                cp.read(os.path.join(d, fn), encoding="utf-8")
                e = cp["Desktop Entry"]
            except Exception:
                continue

            if e.get("Type", "Application") != "Application":
                continue
            if e.getboolean("NoDisplay", fallback=False):
                continue
            if e.getboolean("Hidden", fallback=False):
                continue

            exec_line = e.get("Exec", "")
            if not exec_line:
                continue
            # strip desktop-entry field codes (%u %F %i ...)
            cmd = " ".join(t for t in exec_line.split() if not t.startswith("%"))

            icon_val = e.get("Icon", "")
            if icon_val.startswith("/"):
                icon_path = icon_val if os.path.exists(icon_val) else ""
            else:
                icon_path = icons.get(icon_val, "")

            apps[fn] = {
                # what a compositor reports as a window's app_id / class, so the
                # launcher can put an icon next to an open window
                "id": fn[:-len(".desktop")],
                "wmclass": e.get("StartupWMClass", ""),
                "name": e.get("Name", fn),
                "comment": e.get("Comment", ""),
                "categories": e.get("Categories", ""),
                "keywords": e.get("Keywords", ""),
                "icon": icon_path,
                "exec": cmd,
                "terminal": e.getboolean("Terminal", fallback=False),
            }

    out = sorted(apps.values(), key=lambda a: a["name"].lower())
    json.dump(out, sys.stdout)


if __name__ == "__main__":
    main()
