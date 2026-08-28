import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQml.Models
import Quickshell
import Quickshell.Wayland
import Quickshell.Io

ShellRoot {
    id: root

    // Tracks which network the user clicked to enter a password
    property string selectedSsid: ""

    Timer {
        id: exitTimer
        interval: 150
        onTriggered: Qt.quit()
    }

    // --- PYWAL ENGINE ---
    QtObject {
        id: pywal
        property color bg: "#1e1e2e"
        property color fg: "#cdd6f4"
        property color surface: "#313244"
        property color border: "#45475a"
        property color accent: "#89b4fa"
        property color selection: "#585b70"
    }

    Process {
        command: ["sh", "-c", "cat ~/.cache/wal/colors.json 2>/dev/null | tr -d '\n'"]
        running: true
        stdout: SplitParser { onRead: (line) => {
            try {
                let wal = JSON.parse(line);
                pywal.bg = wal.special.background;
                pywal.fg = wal.special.foreground;
                pywal.surface = Qt.lighter(wal.special.background, 1.5);
                pywal.border = wal.colors.color8;
                pywal.accent = wal.colors.color4;
                pywal.selection = Qt.lighter(wal.special.background, 2.0);
            } catch(e) {}
        }}
    }

    // --- NETWORK SCANNER ---
    ListModel { id: wifiModel }

    Process {
        id: wifiScanner
        running: true
        // Python script to parse nmcli safely, sort active first, then by signal strength
        command: ["python3", "-c", "import subprocess, json\ntry:\n out = subprocess.check_output(['nmcli', '-t', '-f', 'ACTIVE,SSID,SIGNAL,SECURITY', 'dev', 'wifi']).decode()\n networks = []; seen = set()\n for line in out.strip().split('\\n'):\n  parts = line.split(':')\n  if len(parts) >= 4:\n   active = parts[0] == 'yes'; ssid = parts[1]; signal = int(parts[2]) if parts[2].isdigit() else 0; sec = parts[3]\n   if ssid and ssid not in seen:\n    seen.add(ssid)\n    networks.append({'active': active, 'ssid': ssid, 'signal': signal, 'secure': sec != '' and sec != '--'})\n print(json.dumps(sorted(networks, key=lambda x: (-x['active'], -x['signal']))))\nexcept:\n print('[]')"]
        stdout: SplitParser { onRead: (line) => {
            try {
                let data = JSON.parse(line);
                wifiModel.clear();
                for (let net of data) wifiModel.append(net);
            } catch(e) {}
        }}
    }

    // Refreshes the network list every 10 seconds
    Timer {
        interval: 10000; running: true; repeat: true
        onTriggered: wifiScanner.running = true
    }

    // --- CONNECTION EXECUTOR ---
    Process {
        id: execProcess
        function connectWifi(ssid, password) {
            let cmd = password === "" ? "nmcli dev wifi connect '" + ssid + "'" : "nmcli dev wifi connect '" + ssid + "' password '" + password + "'";
            command = ["sh", "-c", "nohup " + cmd + " >/dev/null 2>&1 &"];
            running = true;
            // Instantly rescan to show the new connection state
            rescanTimer.start();
        }
    }
    Timer {
        id: rescanTimer
        interval: 3000 // Give nmcli 3 seconds to connect before rescanning
        onTriggered: wifiScanner.running = true
    }

    // --- UI LAYOUT ---
    PanelWindow {
        id: qsWindow
        screen: Quickshell.focusedScreen
        WlrLayershell.layer: WlrLayershell.Overlay
        WlrLayershell.namespace: "quickshell-wifi"
        WlrLayershell.keyboardFocus: WlrLayershell.OnDemand

        anchors { top: true; bottom: true; left: true; right: true }
        color: "transparent"

        MouseArea { anchors.fill: parent; onClicked: Qt.quit() }

        Item {
            anchors.fill: parent
            focus: true
            Keys.onEscapePressed: Qt.quit()

            Rectangle {
                id: mainBackground
                anchors { top: parent.top; right: parent.right; topMargin: 10; rightMargin: 10 }

                width: 380
                height: 500 // Fixed height for a scrollable list

                color: pywal.bg
                radius: 16
                border.color: pywal.border
                border.width: 2
                clip: true

                MouseArea { anchors.fill: parent }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 15
                    spacing: 15

                    // HEADER
                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            text: "Wi-Fi Networks"
                            font.bold: true; font.pixelSize: 18
                            color: pywal.fg
                            Layout.fillWidth: true
                        }
                        // Manual Refresh Button
                        Rectangle {
                            width: 32; height: 32; radius: 8
                            color: refreshMouse.containsMouse ? pywal.selection : "transparent"
                            Text { anchors.centerIn: parent; text: ""; font.pixelSize: 14; color: pywal.fg }
                            MouseArea {
                                id: refreshMouse; anchors.fill: parent; hoverEnabled: true
                                onClicked: { wifiModel.clear(); wifiScanner.running = true; }
                            }
                        }
                    }

                    Rectangle { Layout.fillWidth: true; height: 1; color: pywal.surface }

                    // NETWORK LIST
                    ListView {
                        id: networkList
                        Layout.fillWidth: true; Layout.fillHeight: true
                        spacing: 8
                        clip: true
                        model: wifiModel

                        delegate: Rectangle {
                            width: networkList.width

                            // Dynamically expand height if this network is clicked to show the password field
                            property bool isExpanded: root.selectedSsid === model.ssid && !model.active
                            height: isExpanded ? 110 : 60

                            radius: 10
                            color: model.active ? pywal.surface : (itemMouse.containsMouse ? pywal.surface : "#00000000")
                            border.color: model.active ? pywal.accent : "transparent"
                            border.width: 1

                            // Behavior adds a smooth slide animation when expanding/collapsing
                            Behavior on height { NumberAnimation { duration: 150; easing.type: Easing.OutQuad } }

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 12
                                spacing: 0

                                // Top Row: Icon, SSID, Lock
                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 15

                                    // Dynamic Signal Icon
                                    Image {
                                        Layout.preferredWidth: 24; Layout.preferredHeight: 24
                                        source: {
                                            if (model.signal > 75) return "image://icon/network-wireless-signal-excellent";
                                            if (model.signal > 50) return "image://icon/network-wireless-signal-good";
                                            if (model.signal > 25) return "image://icon/network-wireless-signal-ok";
                                            return "image://icon/network-wireless-signal-weak";
                                        }
                                        fillMode: Image.PreserveAspectFit
                                    }

                                    ColumnLayout {
                                        Layout.fillWidth: true; spacing: 2
                                        Text {
                                            text: model.ssid; font.bold: true; font.pixelSize: 14
                                            color: model.active ? pywal.accent : pywal.fg; elide: Text.ElideRight
                                        }
                                        Text {
                                            text: model.active ? "Connected" : (model.secure ? "Secured" : "Open")
                                            font.pixelSize: 11; opacity: 0.7; color: pywal.fg
                                        }
                                    }

                                    // Lock Icon for secure networks
                                    Text {
                                        visible: model.secure && !model.active
                                        text: ""; font.pixelSize: 14; color: pywal.fg; opacity: 0.5
                                    }
                                }

                                // Bottom Row: Hidden Password Input
                                RowLayout {
                                    Layout.fillWidth: true
                                    Layout.topMargin: 12
                                    visible: parent.parent.isExpanded
                                    opacity: parent.parent.isExpanded ? 1 : 0
                                    Behavior on opacity { NumberAnimation { duration: 150 } }

                                    Rectangle {
                                        Layout.fillWidth: true; height: 36; radius: 8
                                        color: Qt.darker(pywal.bg, 1.2); border.color: pywal.border; border.width: 1
                                        TextInput {
                                            id: passInput
                                            anchors.fill: parent; anchors.margins: 10
                                            color: pywal.fg; font.pixelSize: 14
                                            verticalAlignment: TextInput.AlignVCenter
                                            echoMode: TextInput.Password // Hides characters
                                            Keys.onReturnPressed: {
                                                root.selectedSsid = "";
                                                execProcess.connectWifi(model.ssid, text);
                                            }
                                        }
                                    }

                                    // Connect Button
                                    Rectangle {
                                        width: 80; height: 36; radius: 8
                                        color: pywal.accent
                                        Text { anchors.centerIn: parent; text: "Connect"; font.bold: true; font.pixelSize: 13; color: pywal.bg }
                                        MouseArea {
                                            anchors.fill: parent
                                            onClicked: {
                                                root.selectedSsid = "";
                                                execProcess.connectWifi(model.ssid, passInput.text);
                                            }
                                        }
                                    }
                                }
                            }

                            // The main click handler for the network item
                            MouseArea {
                                id: itemMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                // Don't let this intercept clicks if the password area is expanded
                                enabled: !parent.isExpanded
                                onClicked: {
                                    if (model.active) return; // Do nothing if already connected
                                    if (!model.secure) {
                                        // Connect instantly if it is an open network
                                        execProcess.connectWifi(model.ssid, "");
                                    } else {
                                        // Expand the password prompt
                                        root.selectedSsid = model.ssid;
                                        passInput.forceActiveFocus();
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
