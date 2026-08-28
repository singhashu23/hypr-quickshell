import QtQuick
import Quickshell
import Quickshell.Io
import qs

// nmcli-backed. Quickshell's Networking module is still young, and nmcli is
// already what the rest of these dotfiles use.
Pill {
    id: root
    property string kind: ""     // wifi | ethernet | ""
    property string ssid: ""
    property int strength: 0

    Process {
        id: probe
        command: ["sh", "-c",
            "nmcli -t -f TYPE,STATE,CONNECTION device status | grep ':connected:' | head -1; " +
            "nmcli -t -f IN-USE,SIGNAL device wifi list 2>/dev/null | grep '^\\*' | head -1"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split("\n").filter(l => l)
                root.kind = ""; root.ssid = ""; root.strength = 0
                for (const l of lines) {
                    if (l.startsWith("*")) {
                        root.strength = parseInt(l.split(":")[1]) || 0
                    } else {
                        const p = l.split(":")
                        root.kind = p[0] === "wifi" ? "wifi" : "ethernet"
                        root.ssid = p[2] || ""
                    }
                }
            }
        }
    }

    Timer { interval: 10000; running: true; repeat: true; onTriggered: probe.running = true }

    onClicked: Quickshell.execDetached(["sh", "-c", "nm-connection-editor || network_menu"])

    IconLabel {
        icon: root.kind === "ethernet" ? "󰈀"
            : root.kind === "wifi" ? (root.strength > 70 ? "󰤨" : root.strength > 40 ? "󰤥" : "󰤟")
            : "󰤭"
        color: root.kind === "" ? Theme.red : Theme.sky
        label: root.kind === "wifi" ? root.ssid : root.kind === "ethernet" ? "wired" : "offline"
    }
}
