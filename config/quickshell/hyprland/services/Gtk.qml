pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Mirrors the desktop's GTK settings so the shell matches the rest of the
// session instead of inventing its own look.
Singleton {
    id: root

    property string theme: "Adwaita"
    property string iconTheme: "Adwaita"
    property string fontName: "Cantarell"
    property int fontSize: 11
    property bool preferDark: true

    Process {
        running: true
        command: ["sh", "-c",
            "gsettings get org.gnome.desktop.interface gtk-theme; " +
            "gsettings get org.gnome.desktop.interface icon-theme; " +
            "gsettings get org.gnome.desktop.interface font-name; " +
            "gsettings get org.gnome.desktop.interface color-scheme"]
        stdout: StdioCollector {
            onStreamFinished: {
                const l = text.trim().split("\n").map(s => s.trim().replace(/^'|'$/g, ""))
                if (l.length < 4) return
                root.theme = l[0]
                root.iconTheme = l[1]

                // "Cantarell 11" -> family + size
                const m = l[2].match(/^(.*?)\s+(\d+)$/)
                if (m) { root.fontName = m[1]; root.fontSize = parseInt(m[2]) }
                else root.fontName = l[2]

                root.preferDark = l[3].indexOf("dark") !== -1
            }
        }
    }
}
