pragma Singleton

import QtQuick
import Quickshell
import qs.services

// Design tokens for the whole shell.
//
// The language follows ryoku (github.com/neur0map/ryoku-arch): paper and ink —
// warm bone type on pure black — with the frame retinting live from the
// wallpaper. So the *ground* is fixed and near-black and the *type* is a fixed
// warm bone, because those two carry legibility; pywal drives the accents,
// borders and glow, which is where wallpaper colour actually belongs.
//
// Surfaces are islands: discrete rounded slabs separated by real gaps, sharing
// one motion language.
Singleton {
    id: root

    property bool usePywal: true
    property bool pywalStatusColors: false
    // true  -> pure black ground, bone type (ryoku)
    // false -> tint the ground with the wallpaper too
    property bool inkAndPaper: true

    readonly property bool wal: usePywal && Pywal.ready

    // Blend two colours; t=0 gives a, t=1 gives b.
    // Qt.darker(c, 1.0) is a no-op that coerces a string like "black" into a
    // real colour — without it the .r/.g/.b reads below yield NaN.
    function mix(a, b, t) {
        const ca = Qt.darker(a, 1.0)
        const cb = Qt.darker(b, 1.0)
        return Qt.rgba(ca.r + (cb.r - ca.r) * t,
                       ca.g + (cb.g - ca.g) * t,
                       ca.b + (cb.b - ca.b) * t, 1)
    }

    function alpha(c, a) {
        const cc = Qt.darker(c, 1.0)
        return Qt.rgba(cc.r, cc.g, cc.b, a)
    }

    // ---- ink & paper ----
    readonly property color ink:  "#000000"          // pure black ground
    readonly property color bone: "#e8e2d6"          // warm bone type

    readonly property color walBg: wal ? Pywal.background : "#1e1e2e"
    readonly property color walFg: wal ? Pywal.foreground : "#cdd6f4"

    // ---- surfaces ----
    readonly property color base:     inkAndPaper ? ink : walBg
    readonly property color island:   inkAndPaper ? mix(ink, walBg, 0.35) : mix(walBg, "black", 0.25)
    readonly property color surface0: mix(island, bone, 0.09)
    readonly property color surface1: mix(island, bone, 0.16)
    readonly property color surface2: mix(island, bone, 0.24)

    // ---- type ----
    readonly property color text:    inkAndPaper ? bone : walFg
    readonly property color subtext: mix(text, base, 0.35)
    readonly property color overlay: mix(text, base, 0.60)

    // ---- accents: this is where the wallpaper lives ----
    readonly property color accent:    wal ? Pywal.color(4, "#cba6f7") : "#cba6f7"
    readonly property color accentAlt: wal ? Pywal.color(6, "#89dceb") : "#89dceb"
    readonly property color mauve:     wal ? Pywal.color(5, "#cba6f7") : "#cba6f7"
    readonly property color blue:      wal ? Pywal.color(4, "#89b4fa") : "#89b4fa"
    readonly property color sky:       wal ? Pywal.color(6, "#89dceb") : "#89dceb"
    readonly property color teal:      wal ? Pywal.color(2, "#94e2d5") : "#94e2d5"
    readonly property color peach:     wal ? Pywal.color(3, "#fab387") : "#fab387"

    // hairline that lifts an island off the wallpaper
    readonly property color border: alpha(mix(accent, bone, 0.35), 0.22)

    // what "this one is selected" looks like everywhere: the accent, at the
    // weight a filled row can carry without fighting the type on top of it
    readonly property color selection:       alpha(accent, 0.28)
    readonly property color selectionBorder: alpha(accent, 0.55)

    // ---- status: must keep reading as signals ----
    readonly property color red:    pywalStatusColors && wal ? Pywal.color(1, "#f38ba8") : "#f38ba8"
    readonly property color green:  pywalStatusColors && wal ? Pywal.color(2, "#a6e3a1") : "#a6e3a1"
    readonly property color yellow: pywalStatusColors && wal ? Pywal.color(3, "#f9e2af") : "#f9e2af"

    // ---- metrics ----
    readonly property int barHeight:    38
    readonly property int barMargin:     8   // gap from the screen edge
    readonly property int islandGap:     8   // gap *between* islands
    readonly property int gap:           8   // gap between items inside an island
    readonly property int padding:      12
    readonly property int radius:       14   // island corner
    readonly property int radiusSmall:  10
    readonly property int borderWidth:   1

    // ---- type ----
    // Nerd Font for the bar: the glyph icons live in it.
    readonly property string fontFamily: "JetBrainsMono Nerd Font"
    // Prose follows the desktop's GTK font.
    readonly property string uiFont: Gtk.fontName
    readonly property int fontSize: 13
    readonly property int fontSizeLarge: 16

    // ---- one motion language ----
    readonly property int animFast:   140
    readonly property int animNormal: 220
    readonly property int animSlow:   360
    readonly property int easing: Easing.OutCubic
}
