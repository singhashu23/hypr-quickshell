import QtQuick
import Quickshell
import Quickshell.Io
import qs
import qs.modules.controlcenter

Column {
    id: root
    spacing: Theme.gap

    property bool wifiOn: false
    property var nets: []
    property string detail: ""
    property string err: ""
    property bool scanning: false

    Process {
        id: state
        running: true
        command: ["sh", "-c", "nmcli -t radio wifi"]
        stdout: StdioCollector { onStreamFinished: root.wifiOn = text.trim() === "enabled" }
    }

    Process {
        id: scan
        running: true
        // IN-USE:SSID:SIGNAL:SECURITY, strongest first, one row per SSID
        command: ["sh", "-c",
            "nmcli -t -f IN-USE,SSID,SIGNAL,SECURITY device wifi list 2>/dev/null " +
            "| awk -F: 'length($2){ if(!seen[$2]++) print }' | head -24"]
        stdout: StdioCollector {
            onStreamFinished: {
                const out = []
                for (const line of text.trim().split("\n")) {
                    if (!line) continue
                    const p = line.split(":")
                    out.push({
                        active: p[0] === "*",
                        ssid: p[1],
                        signal: parseInt(p[2]) || 0,
                        security: (p[3] && p[3] !== "") ? p[3] : "open"
                    })
                }
                root.nets = out
                root.scanning = false
            }
        }
    }

    Process {
        id: info
        running: true
        command: ["sh", "-c",
            "nmcli -t -f TYPE,STATE,CONNECTION device status | grep ':connected:' | head -1; " +
            "ip -4 -o addr show scope global 2>/dev/null | awk '{print $2\" \"$4}' | head -2"]
        stdout: StdioCollector { onStreamFinished: root.detail = text.trim() }
    }

    Process {
        id: connect
        stdout: StdioCollector { onStreamFinished: { refresh.restart() } }
        stderr: StdioCollector { onStreamFinished: if (text.trim() !== "") root.err = text.trim() }
    }
    Process { id: radio; onExited: refresh.restart() }

    Timer {
        id: refresh
        interval: 1200
        onTriggered: { state.running = true; scan.running = true; info.running = true }
    }
    Timer { interval: 10000; running: true; repeat: true; onTriggered: refresh.restart() }

    CcSection {
        title: "Wi-Fi"

        CcRow {
            icon: root.wifiOn ? "󰤨" : "󰤮"
            title: "Wi-Fi"
            subtitle: root.wifiOn ? "On" : "Off"
            selected: root.wifiOn
            onActivated: {
                radio.command = ["nmcli", "radio", "wifi", root.wifiOn ? "off" : "on"]
                radio.running = true
                root.wifiOn = !root.wifiOn
            }
        }

        CcRow {
            visible: root.wifiOn
            icon: "󰑐"
            title: root.scanning ? "Scanning…" : "Rescan"
            subtitle: root.nets.length + " networks"
            onActivated: { root.scanning = true; root.err = ""; refresh.restart() }
        }
    }

    CcSection {
        title: "Networks"
        visible: root.wifiOn

        Repeater {
            model: root.nets
            delegate: CcRow {
                required property var modelData
                icon: modelData.signal > 75 ? "󰤨" : modelData.signal > 50 ? "󰤥"
                    : modelData.signal > 25 ? "󰤢" : "󰤟"
                title: modelData.ssid
                subtitle: (modelData.active ? "Connected · " : "")
                        + modelData.signal + "%  ·  " + modelData.security
                selected: modelData.active
                onActivated: {
                    if (modelData.active) return
                    root.err = ""
                    connect.command = ["nmcli", "device", "wifi", "connect", modelData.ssid]
                    connect.running = true
                }
            }
        }

        Text {
            visible: root.err !== ""
            width: parent.width
            text: root.err + "\nA network needing a new password is easier in `nmtui` (SUPER+N)."
            color: Theme.red
            wrapMode: Text.WordWrap
            font.family: Theme.uiFont
            font.pixelSize: Theme.fontSize - 1
        }
    }

    CcSection {
        title: "Connection"

        Text {
            width: parent.width
            text: root.detail !== "" ? root.detail : "Not connected"
            color: Theme.subtext
            wrapMode: Text.WordWrap
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize - 1
        }
    }
}
