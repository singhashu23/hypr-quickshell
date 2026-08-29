pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Reads ~/.cache/wal/colors.json and re-reads it whenever pywal rewrites the
// file, so the shell retints the moment the wallpaper changes — no restart.
Singleton {
    id: root

    readonly property string cachePath: Quickshell.env("HOME") + "/.cache/wal/colors.json"

    property bool ready: false
    property string wallpaper: ""
    property color background: "#1e1e2e"
    property color foreground: "#cdd6f4"
    // color0 .. color15
    property var colors: []

    function color(i, fallback) {
        return ready && colors.length > i ? colors[i] : fallback
    }

    FileView {
        id: file
        path: Qt.resolvedUrl("file://" + root.cachePath)
        watchChanges: true
        onFileChanged: reload()

        onLoaded: {
            try {
                const j = JSON.parse(file.text())
                const list = []
                for (let i = 0; i < 16; i++) list.push(j.colors["color" + i])

                root.background = j.special.background
                root.foreground = j.special.foreground
                root.wallpaper  = j.wallpaper ?? ""
                root.colors     = list
                root.ready      = true
            } catch (e) {
                console.warn("Pywal: could not parse colors.json — " + e)
                root.ready = false
            }
        }

        // no pywal cache yet: keep the built-in palette
        onLoadFailed: root.ready = false
    }
}
