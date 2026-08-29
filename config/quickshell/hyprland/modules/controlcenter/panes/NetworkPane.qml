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
    property var saved: []
    property string detail: ""
    property string err: ""
    property bool scanning: false

    // the network currently asking for a password, and what has been typed
    property string authSsid: ""
    property string busySsid: ""

    function isSaved(ssid) { return saved.indexOf(ssid) !== -1 }
    function isOpen(sec) { return sec === "open" || sec === "" || sec === "--" }

    function connect(ssid, pass) {
        root.err = ""
        root.busySsid = ssid
        conn.command = pass && pass !== ""
                     ? ["nmcli", "device", "wifi", "connect", ssid, "password", pass]
                     : ["nmcli", "device", "wifi", "connect", ssid]
        conn.running = true
    }

    function disconnect(ssid) {
        root.err = ""
        root.busySsid = ssid
        conn.command = ["nmcli", "connection", "down", "id", ssid]
        conn.running = true
    }

    Process {
        id: state
        running: true
        command: ["sh", "-c", "nmcli -t radio wifi"]
        stdout: StdioCollector { onStreamFinished: root.wifiOn = text.trim() === "enabled" }
    }

    Process {
        id: scan
        running: true
        command: ["sh", "-c",
            "nmcli -t -f IN-USE,SSID,SIGNAL,SECURITY device wifi list 2>/dev/null " +
            "| awk -F: 'length($2){ if(!seen[$2]++) print }' | head -24; " +
            "echo '---'; nmcli -t -f NAME connection show 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: {
                const parts = text.split("---")
                const out = []
                for (const line of parts[0].trim().split("\n")) {
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
                root.saved = parts.length > 1
                           ? parts[1].trim().split("\n").filter(l => l) : []
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
        id: conn
        onExited: { root.busySsid = ""; refresh.restart() }
        stderr: StdioCollector {
            onStreamFinished: if (text.trim() !== "") root.err = text.trim()
        }
        stdout: StdioCollector {
            onStreamFinished: if (text.indexOf("successfully") !== -1) root.authSsid = ""
        }
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

            delegate: Column {
                id: entry
                required property var modelData
                width: parent.width
                spacing: 0

                // referenced by id, not by walking parents: CcButton is
                // reparented into the row's trailing item, so parent.parent
                // from inside it is not this delegate
                readonly property bool needsPass:
                    !modelData.active && !root.isSaved(modelData.ssid)
                    && !root.isOpen(modelData.security)

                CcRow {
                    icon: modelData.signal > 75 ? "󰤨" : modelData.signal > 50 ? "󰤥"
                        : modelData.signal > 25 ? "󰤢" : "󰤟"
                    title: modelData.ssid
                    subtitle: (modelData.active ? "Connected · " : "")
                            + modelData.signal + "%  ·  " + modelData.security
                            + (!modelData.active && root.isSaved(modelData.ssid) ? "  ·  saved" : "")
                    selected: modelData.active
                    interactive: false

                    CcButton {
                        label: modelData.active ? "Disconnect"
                             : entry.needsPass && root.authSsid !== modelData.ssid
                               ? "Connect…" : "Connect"
                        primary: !modelData.active
                        busy: root.busySsid === modelData.ssid
                        enabled: root.busySsid === ""
                        onClicked: {
                            if (modelData.active) { root.disconnect(modelData.ssid); return }
                            if (entry.needsPass) {
                                // ask here rather than failing at nmcli: a new
                                // secured network cannot be joined without one
                                root.authSsid = root.authSsid === modelData.ssid
                                              ? "" : modelData.ssid
                                root.err = ""
                                return
                            }
                            root.connect(modelData.ssid, "")
                        }
                    }
                }

                // password prompt, shown only for the network being joined
                Rectangle {
                    width: parent.width
                    height: root.authSsid === modelData.ssid ? 48 : 0
                    visible: height > 0
                    clip: true
                    radius: Theme.radiusSmall
                    color: Theme.surface1
                    border.width: Theme.borderWidth
                    border.color: Theme.selectionBorder

                    Behavior on height { NumberAnimation { duration: Theme.animFast } }

                    onVisibleChanged: if (visible) pass.forceActiveFocus()

                    Text {
                        id: lock
                        anchors { left: parent.left; leftMargin: Theme.padding
                                  verticalCenter: parent.verticalCenter }
                        text: "󰌾"
                        color: Theme.accent
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeLarge
                    }

                    TextInput {
                        id: pass
                        anchors { left: lock.right; leftMargin: Theme.gap
                                  right: go.left; rightMargin: Theme.gap
                                  verticalCenter: parent.verticalCenter }
                        echoMode: TextInput.Password
                        passwordCharacter: "•"
                        color: Theme.text
                        font.family: Theme.uiFont
                        font.pixelSize: Theme.fontSize
                        selectByMouse: true
                        selectionColor: Theme.alpha(Theme.accent, 0.35)
                        clip: true

                        Text {
                            anchors.fill: parent
                            visible: pass.text === ""
                            text: "Password for " + modelData.ssid
                            color: Theme.overlay
                            font: pass.font
                            verticalAlignment: Text.AlignVCenter
                        }

                        Keys.onReturnPressed: { root.connect(modelData.ssid, pass.text); pass.text = "" }
                        Keys.onEnterPressed:  { root.connect(modelData.ssid, pass.text); pass.text = "" }
                        Keys.onEscapePressed: { root.authSsid = ""; pass.text = "" }
                    }

                    CcButton {
                        id: go
                        anchors { right: parent.right; rightMargin: Theme.padding
                                  verticalCenter: parent.verticalCenter }
                        label: "Join"
                        primary: true
                        busy: root.busySsid === modelData.ssid
                        enabled: pass.text !== "" && root.busySsid === ""
                        onClicked: { root.connect(modelData.ssid, pass.text); pass.text = "" }
                    }
                }
            }
        }

        Text {
            visible: root.err !== ""
            width: parent.width
            text: root.err
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
