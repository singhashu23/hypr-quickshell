import QtQuick
import Quickshell
import Quickshell.Io
import qs

// intel_backlight via brightnessctl; polled lightly since there is no
// change signal to subscribe to.
Pill {
    id: root
    property int pct: 0

    Process {
        id: readProc
        command: ["sh", "-c", "brightnessctl -m | cut -d, -f4 | tr -d '%'"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const v = parseInt(text.trim())
                if (!isNaN(v)) root.pct = v
            }
        }
    }

    Process { id: setProc }

    Timer {
        interval: 5000; running: true; repeat: true
        onTriggered: readProc.running = true
    }

    onWheel: delta => {
        const next = Math.max(1, Math.min(100, root.pct + (delta > 0 ? 5 : -5)))
        root.pct = next
        setProc.command = ["brightnessctl", "set", next + "%"]
        setProc.running = true
    }

    IconLabel {
        icon: root.pct > 66 ? "󰃠" : root.pct > 33 ? "󰃟" : "󰃞"
        color: Theme.peach
        label: root.pct + "%"
    }
}
