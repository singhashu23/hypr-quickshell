pragma Singleton

import QtQuick
import Quickshell

// Central palette + metrics. Every module reads from here so a retheme is a
// one-file change. Colors are Catppuccin Mocha.
Singleton {
    // backgrounds
    readonly property color base:     "#1e1e2e"
    readonly property color mantle:   "#181825"
    readonly property color crust:    "#11111b"
    readonly property color surface0: "#313244"
    readonly property color surface1: "#45475a"
    readonly property color surface2: "#585b70"

    // text
    readonly property color text:     "#cdd6f4"
    readonly property color subtext:  "#a6adc8"
    readonly property color overlay:  "#6c7086"

    // accents
    readonly property color rosewater: "#f5e0dc"
    readonly property color red:       "#f38ba8"
    readonly property color peach:     "#fab387"
    readonly property color yellow:    "#f9e2af"
    readonly property color green:     "#a6e3a1"
    readonly property color teal:      "#94e2d5"
    readonly property color sky:       "#89dceb"
    readonly property color blue:      "#89b4fa"
    readonly property color mauve:     "#cba6f7"

    readonly property color accent: mauve

    // metrics
    readonly property int barHeight:   34
    readonly property int barMargin:    6
    readonly property int gap:          6
    readonly property int padding:     10
    readonly property int radius:      10

    // type
    readonly property string fontFamily: "JetBrainsMono Nerd Font"
    readonly property int fontSize: 13

    // motion
    readonly property int animFast: 120
    readonly property int animNormal: 200
}
