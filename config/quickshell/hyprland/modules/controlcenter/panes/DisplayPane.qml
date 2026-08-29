import QtQuick
import Quickshell
import Quickshell.Io
import qs
import qs.modules.controlcenter

Column {
    id: root
    spacing: Theme.gap

    property int pct: 0
    property bool has: false

    Process {
        id: read
        running: true
        command: ["sh", "-c", "brightnessctl -m | cut -d, -f4 | tr -d '%'"]
        stdout: StdioCollector {
            onStreamFinished: {
                const v = parseInt(text.trim())
                if (!isNaN(v)) { root.pct = v; root.has = true }
            }
        }
    }
    Process { id: apply }
    Timer { interval: 4000; running: true; repeat: true; onTriggered: read.running = true }

    function set(v) {
        pct = Math.round(Math.max(1, Math.min(100, v * 100)))
        apply.command = ["brightnessctl", "-q", "set", pct + "%"]
        apply.running = true
    }

    CcSection {
        title: "Brightness"

        CcSlider {
            icon: "󰃞"
            value: root.pct / 100
            enabled: root.has
            onMoved: v => root.set(v)
        }

        Text {
            visible: !root.has
            text: "No writable backlight device found"
            color: Theme.overlay
            font.family: Theme.uiFont
            font.pixelSize: Theme.fontSize - 1
        }
    }

    CcSection {
        title: "Presets"

        Row {
            spacing: Theme.gap

            Repeater {
                model: [10, 30, 50, 75, 100]
                delegate: Rectangle {
                    required property int modelData
                    width: 76; height: 38
                    radius: Theme.radiusSmall
                    color: hov.hovered ? Theme.surface1 : Theme.surface0
                    border.width: Theme.borderWidth
                    border.color: Math.abs(root.pct - modelData) < 3
                                ? Theme.selectionBorder : Theme.border
                    Behavior on color { ColorAnimation { duration: Theme.animFast } }
                    HoverHandler { id: hov }
                    TapHandler { onTapped: root.set(modelData / 100) }
                    Text {
                        anchors.centerIn: parent
                        text: modelData + "%"
                        color: Theme.text
                        font.family: Theme.uiFont
                        font.pixelSize: Theme.fontSize
                    }
                }
            }
        }
    }
}
