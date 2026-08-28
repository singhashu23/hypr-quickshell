pragma Singleton

import QtQuick
import Quickshell
import qs.services

// Central palette + metrics. Every module reads from here, so a retheme is a
// one-file change.
//
// With `usePywal` on, the chrome (backgrounds, text, accent) is derived from
// ~/.cache/wal/colors.json and follows the wallpaper live. Status colors stay
// fixed unless `pywalStatusColors` is on too — pywal palettes are often nearly
// monochrome, and a "low battery" warning tinted to match the wallpaper stops
// reading as a warning.
Singleton {
    id: root

    property bool usePywal: true
    property bool pywalStatusColors: false

    readonly property bool wal: usePywal && Pywal.ready

    // Blend two colors; t=0 gives a, t=1 gives b.
    // Qt.darker(c, 1.0) is a no-op that coerces a string like "black" into a
    // real color — without it the .r/.g/.b reads below yield NaN.
    function mix(a, b, t) {
        const ca = Qt.darker(a, 1.0)
        const cb = Qt.darker(b, 1.0)
        return Qt.rgba(ca.r + (cb.r - ca.r) * t,
                       ca.g + (cb.g - ca.g) * t,
                       ca.b + (cb.b - ca.b) * t, 1)
    }

    // ---- fallback palette: Catppuccin Mocha ----
    readonly property color _base:     "#1e1e2e"
    readonly property color _mantle:   "#181825"
    readonly property color _text:     "#cdd6f4"

    // ---- backgrounds ----
    readonly property color base:     wal ? Pywal.background            : _base
    readonly property color mantle:   wal ? mix(base, "black", 0.30)    : _mantle
    readonly property color crust:    wal ? mix(base, "black", 0.50)    : "#11111b"
    readonly property color surface0: wal ? mix(base, text, 0.10)       : "#313244"
    readonly property color surface1: wal ? mix(base, text, 0.18)       : "#45475a"
    readonly property color surface2: wal ? mix(base, text, 0.26)       : "#585b70"

    // ---- text ----
    readonly property color text:     wal ? Pywal.foreground            : _text
    readonly property color subtext:  wal ? mix(text, base, 0.25)       : "#a6adc8"
    readonly property color overlay:  wal ? mix(text, base, 0.50)       : "#6c7086"

    // ---- accents (chrome) ----
    readonly property color accent:    wal ? Pywal.color(4, "#cba6f7")  : "#cba6f7"
    readonly property color rosewater: wal ? Pywal.color(6, "#f5e0dc")  : "#f5e0dc"
    readonly property color mauve:     wal ? Pywal.color(5, "#cba6f7")  : "#cba6f7"
    readonly property color blue:      wal ? Pywal.color(4, "#89b4fa")  : "#89b4fa"
    readonly property color sky:       wal ? Pywal.color(6, "#89dceb")  : "#89dceb"
    readonly property color teal:      wal ? Pywal.color(2, "#94e2d5")  : "#94e2d5"
    readonly property color peach:     wal ? Pywal.color(3, "#fab387")  : "#fab387"

    // ---- status: must stay legible as signals ----
    readonly property color red:    pywalStatusColors && wal ? Pywal.color(1, "#f38ba8") : "#f38ba8"
    readonly property color green:  pywalStatusColors && wal ? Pywal.color(2, "#a6e3a1") : "#a6e3a1"
    readonly property color yellow: pywalStatusColors && wal ? Pywal.color(3, "#f9e2af") : "#f9e2af"

    // ---- metrics ----
    readonly property int barHeight:  34
    readonly property int barMargin:   6
    readonly property int gap:         6
    readonly property int padding:    10
    readonly property int radius:     10

    // ---- type ----
    readonly property string fontFamily: "JetBrainsMono Nerd Font"
    readonly property int fontSize: 13

    // ---- motion ----
    readonly property int animFast: 120
    readonly property int animNormal: 200
}
