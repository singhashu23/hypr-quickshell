-- Hyprland config, migrated from hyprland.conf (hyprlang) to the Lua format
-- introduced in Hyprland 0.57. When both files exist Hyprland loads this one;
-- hyprland.conf is kept only as a reference.
--
-- API reference: https://wiki.hypr.land/configuring/
-- Type stubs:    /usr/share/hypr/stubs/hl.meta.lua


-------------------------
---- PYWAL COLOURS ----
-------------------------

-- ~/.cache/wal/colors-hyprland.conf is still written by the pywal template in
-- hyprlang syntax ($name = value). Rather than keep a second template in sync,
-- parse it here. randWall ends with `hyprctl reload`, which re-runs this file,
-- so the borders retint on every wallpaper change exactly as before.
local function load_wal_colors()
    local colors = {}
    local path = os.getenv("HOME") .. "/.cache/wal/colors-hyprland.conf"
    local f = io.open(path, "r")
    if not f then return colors end
    for line in f:lines() do
        local name, value = line:match("^%s*%$([%w_]+)%s*=%s*(.-)%s*$")
        if name then colors[name] = value end
    end
    f:close()
    return colors
end

local wal = load_wal_colors()
-- Fallbacks for a first boot before pywal has ever run.
local color0 = wal.color0 or "rgba(595959aa)"
local color4 = wal.color4 or "rgba(33ccffee)"
local color6 = wal.color6 or "rgba(00ff99ee)"


------------------
---- MONITORS ----
------------------

hl.monitor({ output = "eDP-1", mode = "2880x1800@120", position = "auto", scale = 1.6, bitdepth = 10 })
hl.monitor({ output = "DP-4",  mode = "2560x1440@100", position = "auto", scale = 1.0, bitdepth = 10 })
hl.monitor({ output = "DP-5",  mode = "2560x1440@144", position = "auto", scale = 1.1, bitdepth = 10 })

-- Fix scaling on Xorg apps
hl.config({
    xwayland = {
        force_zero_scaling = true,
    },
})


-------------------------------
---- ENVIRONMENT VARIABLES ----
-------------------------------

-- Without this Qt never loads an icon theme and every image://icon lookup
-- returns a magenta placeholder — tray icons and notification icons included.
hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")

hl.env("GDK_SCALE", "1")
hl.env("XDG_SESSION_TYPE", "wayland")
hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")

-- The old config set XCURSOR_SIZE twice (32, then 24); the later one won.
hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")


---------------------
---- MY PROGRAMS ----
---------------------

local terminal    = "kitty"
local fileManager = "nautilus"


-------------------
---- AUTOSTART ----
-------------------

-- "hyprland.start" fires once per session, which is what exec-once meant.
-- That matters: randWall ends with `hyprctl reload`, and gtk-pywal owns the
-- gtk-theme and libadwaita overrides — re-running the gsettings lines on every
-- reload would clobber the theme it had just built. So this block sets only
-- the keys pywal has no opinion about.
local gnome_schema = "org.gnome.desktop.interface"

hl.on("hyprland.start", function()
    hl.exec_cmd("qs -c hyprland")
    hl.exec_cmd("initRandomWallpaper")
    hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")
    hl.exec_cmd("xrdb -merge ~/.Xresources")

    hl.exec_cmd("gsettings set " .. gnome_schema .. " icon-theme 'Flatery'")
    hl.exec_cmd("gsettings set " .. gnome_schema .. " color-scheme prefer-dark")
    hl.exec_cmd("gsettings set " .. gnome_schema .. " font-name 'JetBrains Mono'")

    -- swaync is not installed, and the Quickshell shell provides the
    -- org.freedesktop.Notifications daemon itself; don't start both.
    hl.exec_cmd("/usr/lib/polkit-kde-authentication-agent-1")
    hl.exec_cmd("hyprctl setcursor Vimix-white-cursors 28")
    hl.exec_cmd("idleLock")
end)


-----------------------
---- LOOK AND FEEL ----
-----------------------

hl.config({
    general = {
        gaps_in  = 2,
        gaps_out = 3,

        border_size = 1,

        col = {
            inactive_border = color0,
            active_border   = { colors = { color4, color6 }, angle = 45 },
        },

        resize_on_border = false,
        allow_tearing    = false,

        layout = "dwindle",
    },

    decoration = {
        rounding = 10,

        active_opacity   = 1.0,
        inactive_opacity = 1.0,

        blur = {
            enabled  = true,
            size     = 3,
            passes   = 1,
            vibrancy = 0.1696,
        },
    },

    animations = {
        enabled = true,
    },

    dwindle = {
        preserve_split = true,
    },

    master = {
        new_status = "master",
    },

    misc = {
        force_default_wallpaper = -1,
        disable_hyprland_logo   = false,
    },
})

hl.curve("myBezier", { type = "bezier", points = { {0.05, 0.9}, {0.1, 1.05} } })

hl.animation({ leaf = "windows",     enabled = true, speed = 7,  bezier = "myBezier" })
hl.animation({ leaf = "windowsOut",  enabled = true, speed = 7,  bezier = "default", style = "popin 80%" })
hl.animation({ leaf = "border",      enabled = true, speed = 10, bezier = "default" })
hl.animation({ leaf = "borderangle", enabled = true, speed = 8,  bezier = "default" })
hl.animation({ leaf = "fade",        enabled = true, speed = 7,  bezier = "default" })
hl.animation({ leaf = "workspaces",  enabled = true, speed = 6,  bezier = "default" })


---------------
---- INPUT ----
---------------

hl.config({
    input = {
        kb_layout  = "us",
        kb_variant = "",
        kb_model   = "",
        kb_options = "",
        kb_rules   = "",

        follow_mouse = 1,
        sensitivity  = 0,

        touchpad = {
            natural_scroll = false,
        },
    },
})

hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })
hl.gesture({ fingers = 3, direction = "vertical",   action = "float", scale = 1.5 })

hl.device({
    name        = "epic-mouse-v1",
    sensitivity = -0.5,
})


---------------------
---- KEYBINDINGS ----
---------------------

local mainMod = "SUPER"
local function key(k) return mainMod .. " + " .. k end
local function qs(target) return hl.dsp.exec_cmd("qs -c hyprland ipc call " .. target) end

hl.bind(key("K"),      hl.dsp.exec_cmd(terminal, { float = true }))
hl.bind(key("T"),      hl.dsp.exec_cmd("alacritty"))
hl.bind(key("C"),      hl.dsp.window.close())
hl.bind(key("M"),      hl.dsp.exit())
hl.bind(key("Return"), hl.dsp.exec_cmd(terminal))
hl.bind(key("F"),      hl.dsp.exec_cmd(fileManager))
hl.bind(key("V"),      hl.dsp.window.float({ action = "toggle" }))
hl.bind(key("P"),      hl.dsp.window.pseudo())

-- Quickshell: launcher (apps, open windows, calculator), control centre, power menu
hl.bind(key("space"), qs("launcher toggle"))
hl.bind(key("W"),     qs("launcher windows"))
hl.bind(key("A"),     qs("controlcenter toggle"))
hl.bind(key("Q"),     qs("powermenu toggle"))

hl.bind(key("X"),     hl.dsp.exec_cmd("wlogout --protocol layer-shell -b 5 -T 400 -B 400"))
hl.bind(key("L"),     hl.dsp.exec_cmd("waylandLockscreen"))
hl.bind(key("N"),     hl.dsp.exec_cmd("kitty -e nmtui"))
hl.bind(key("slash"), hl.dsp.exec_cmd("fuzzel"))
hl.bind("CTRL + ALT + T", hl.dsp.exec_cmd("/home/asmj/.local/bin/randWall"))

-- Screen brightness (hold to repeat)
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl -d intel_backlight s 5%-"), { repeating = true })
hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd("brightnessctl -d intel_backlight s 5%+"), { repeating = true })

-- Volume, limited to 150%
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1.5 @DEFAULT_AUDIO_SINK@ 5%+"), { repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),        { repeating = true })
hl.bind("XF86AudioMute",        hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"))

-- Screenshots: window / monitor / region
hl.bind(key("Print"),     hl.dsp.exec_cmd("hyprshot -m window"))
hl.bind("Print",          hl.dsp.exec_cmd("hyprshot -m output"))
hl.bind("SHIFT + Print",  hl.dsp.exec_cmd("hyprshot -m region"))

-- Move focus with mainMod + arrow keys
hl.bind(key("left"),  hl.dsp.focus({ direction = "left" }))
hl.bind(key("right"), hl.dsp.focus({ direction = "right" }))
hl.bind(key("up"),    hl.dsp.focus({ direction = "up" }))
hl.bind(key("down"),  hl.dsp.focus({ direction = "down" }))

-- Switch workspaces with mainMod + [0-9]; move the window with mainMod + SHIFT + [0-9]
for i = 1, 10 do
    local k = i % 10 -- workspace 10 is on key 0
    hl.bind(key(k),              hl.dsp.focus({ workspace = i }))
    hl.bind(key("SHIFT + " .. k), hl.dsp.window.move({ workspace = i }))
end
hl.bind(key("F1"), hl.dsp.focus({ workspace = 11 }))

-- Cycle through existing workspaces
hl.bind(key("mouse_down"),     hl.dsp.focus({ workspace = "e+1" }))
hl.bind(key("mouse_up"),       hl.dsp.focus({ workspace = "e-1" }))
hl.bind("CTRL + ALT + left",   hl.dsp.focus({ workspace = "e-1" }))
hl.bind("CTRL + ALT + right",  hl.dsp.focus({ workspace = "e+1" }))

-- Move/resize windows with mainMod + LMB/RMB and dragging
hl.bind(key("mouse:272"), hl.dsp.window.drag(),   { mouse = true })
hl.bind(key("mouse:273"), hl.dsp.window.resize(), { mouse = true })

-- Scratchpad
hl.bind(key("S"), hl.dsp.workspace.toggle_special("my-scratchpad"))


--------------------------------
---- WINDOWS AND WORKSPACES ----
--------------------------------

hl.window_rule({
    name  = "xwayland-video-bridge-fixes",
    match = { class = "xwaylandvideobridge" },

    no_initial_focus = true,
    no_anim          = true,
    no_blur          = true,
    max_size         = "1 1",
    opacity          = "0.0",
})
