import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Io

ShellRoot {
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: window
            required property var modelData
            screen: modelData
            anchors { top: true; bottom: true; left: true }
            implicitWidth: 52
            color: "transparent"

            WlrLayershell.namespace: "quickshell-bar"
            WlrLayershell.layer: WlrLayershell.Top
            WlrLayershell.exclusiveZone: 52

            Process {
                id: commandRunner
                function run(cmd) { command = cmd; running = true; }
            }

            // --- PYWAL COLOR ENGINE (SINGLE LOAD) ---
            QtObject {
                id: pywal
                property color bg: "#1a1b26"
                property color fg: "#c0caf5"
                property color surface: "#24283b"
                property color border: "#444b6a"
                property color red: "#f7768e"
                property color green: "#9ece6a"
                property color yellow: "#e0af68"
                property color blue: "#7aa2f7"
                property color purple: "#bb9af7"
                property color grey: "#565f89"
                property color color2: "#9ece6a"
            }

            Process {
                // Removed 'while true' loop to only poll once on startup
                command: ["sh", "-c", "cat ~/.cache/wal/colors.json 2>/dev/null | tr -d '\n'"]
                running: true
                stdout: SplitParser { onRead: (line) => {
                    try {
                        let wal = JSON.parse(line);
                        pywal.bg = wal.special.background;
                        pywal.fg = wal.special.foreground;
                        pywal.surface = Qt.lighter(wal.special.background, 1.2);
                        pywal.border = wal.colors.color8;
                        pywal.red = wal.colors.color1;
                        pywal.green = wal.colors.color2;
                        pywal.yellow = wal.colors.color3;
                        pywal.blue = wal.colors.color4;
                        pywal.purple = wal.colors.color5;
                        pywal.grey = wal.colors.color8;
                        pywal.color2 = wal.colors.color2;
                    } catch(e) {}
                }}
            }

            // --- LIVE DATA TRACKERS ---
            // (Trackers remain active for real-time UI updates)

            property string netIcon: "󰖪"
            property string netStatus: "Disconnected"
            property bool netActive: false
            Process {
                command: ["sh", "-c", "while true; do TYPE=$(nmcli -t -f TYPE,STATE dev | grep -E ':connected|:activated|:fully' | head -n 1 | cut -d: -f1); if [ \"$TYPE\" = \"wifi\" ]; then echo \"WIFI|Connected\"; elif [ \"$TYPE\" = \"802-3-ethernet\" ]; then echo \"LAN|Connected\"; else echo \"NONE|Disconnected\"; fi; sleep 10; done"]
                running: true
                stdout: SplitParser { onRead: (line) => {
                    let parts = line.split("|");
                    if (parts.length < 2) return;
                    netStatus = parts[1].trim();
                    let type = parts[0].trim();
                    if (type === "WIFI") { netIcon = "󰖩"; netActive = true; }
                    else if (type === "LAN") { netIcon = "󰈀"; netActive = true; }
                    else { netIcon = "󰖪"; netActive = false; }
                }}
            }

            property string btIcon: "󰂲"
            property bool btActive: false
            Process {
                command: ["sh", "-c", "while true; do bluetoothctl show 2>/dev/null | grep 'Powered:'; sleep 3; done"]
                running: true
                stdout: SplitParser { onRead: (line) => { btActive = line.includes("yes"); btIcon = btActive ? "󰂯" : "󰂲"; }}
            }

            property string volIcon: "󰕾"
            property string volPerc: "0"
            Process {
                command: ["sh", "-c", "while true; do wpctl get-volume @DEFAULT_AUDIO_SINK@; sleep 0.2; done"]
                running: true
                stdout: SplitParser { onRead: (line) => {
                    if (!line || !line.includes("Volume:")) return;
                    let val = parseFloat(line.split(" ")[1]);
                    volPerc = Math.round(val * 100).toString();
                    volIcon = line.includes("[MUTED]") ? "󰝟" : (val > 0.5 ? "󰕾" : "󰖀");
                }}
            }

            property string battIcon: "󰁹"
            property int battState: 1
            property string battPerc: "0"
            Process {
                command: ["sh", "-c", "while true; do cap=$(cat /sys/class/power_supply/BAT*/capacity 2>/dev/null); stat=$(cat /sys/class/power_supply/BAT*/status 2>/dev/null); echo \"$cap|$stat\"; sleep 5; done"]
                running: true
                stdout: SplitParser { onRead: (line) => {
                    if (!line || !line.includes("|")) return;
                    let parts = line.split("|");
                    let cap = parseInt(parts[0]);
                    let stat = parts[1].trim();
                    battPerc = cap.toString();
                    if (stat === "Charging" || stat === "Full") { battIcon = "󰂄"; battState = 4; }
                    else {
                        if (cap > 70) { battIcon = "󰁹"; battState = 1; }
                        else if (cap > 20) { battIcon = "󰁾"; battState = 2; }
                        else { battIcon = "󰁺"; battState = 3; }
                    }
                }}
            }

            property string brightPerc: "0"
            Process {
                command: ["sh", "-c", "while true; do brightnessctl -m | awk -F, '{print $4}' | tr -d '%'; sleep 0.2; done"]
                running: true
                stdout: SplitParser { onRead: (line) => { if (line.trim() !== "") brightPerc = line.trim(); }}
            }

            // -- Launcher --
            Process {
                id: launcherProcess
                // We split the command into an array.
                // "sh" is the program, "-c" tells it to run the next string, and the '&' detaches it.
                command: ["sh", "-c", "QT_QPA_PLATFORMTHEME=qt6ct quickshell -p $HOME/.config/quickshell/masterLauncher.qml"]
            }

            // -- Powermenu --
            Process {
                id: powermenuProcess
                // We split the command into an array.
                // "sh" is the program, "-c" tells it to run the next string, and the '&' detaches it.
                command: ["sh", "-c", "QT_QPA_PLATFORMTHEME=qt6ct quickshell -p $HOME/.config/quickshell/powermenu.qml"]
            }

            // --- CLOCK DATA ---
            property string hours: Qt.formatDateTime(new Date(), "HH")
            property string minutes: Qt.formatDateTime(new Date(), "mm")

            Timer {
                interval: 1000 // Checks every second to ensure the minute flip is precise
                running: true
                repeat: true
                onTriggered: {
                    let now = new Date();
                    hours = Qt.formatDateTime(now, "HH");
                    minutes = Qt.formatDateTime(now, "mm");
                }
            }

            // --- UI LAYOUT ---
            Rectangle {
                anchors { fill: parent; topMargin: 8; bottomMargin: 8; leftMargin: 4; rightMargin: 4 }
                color: pywal.bg
                radius: 10
                border.color: pywal.border
                border.width: 1

                ColumnLayout {
                    anchors.fill: parent; anchors.margins: 4; spacing: 12

                    Rectangle {
                        Layout.alignment: Qt.AlignHCenter; Layout.topMargin: 3
                        implicitWidth: 34; implicitHeight: 34; radius: 8; color: pywal.color2
                        Text { anchors.centerIn: parent; text: ""; color: pywal.bg; font.pixelSize: 18 }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                launcherProcess.running = true;
                            }
                        }
                    }

                    Workspaces {
                        Layout.alignment: Qt.AlignHCenter; monitorName: modelData.name
                        accentColor: pywal.color2; baseColor: pywal.bg; surfaceColor: pywal.surface
                    }

                    Item { Layout.fillHeight: true; Layout.fillWidth: true }

                    Column {
                        Layout.alignment: Qt.AlignHCenter
                        spacing: 2

                        Text { text: "󰥔"; font.pixelSize: 16; color: pywal.green; anchors.horizontalCenter: parent.horizontalCenter }

                        Text {
                            text: hours
                            color: pywal.purple
                            font.bold: true
                            font.pixelSize: 15
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                        Text {
                            text: minutes
                            color: pywal.blue
                            font.bold: true
                            font.pixelSize: 15
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                    }

                    //Item { Layout.fillHeight: true; Layout.fillWidth: true }

                    Column {
                        Layout.alignment: Qt.AlignHCenter; spacing: 10
                        Rectangle {
                            anchors.horizontalCenter: parent.horizontalCenter
                            implicitWidth: 36; implicitHeight: 70; radius: 18; color: pywal.surface
                            Column {
                                anchors.centerIn: parent; spacing: 12
                                Text { text: netIcon; font.pixelSize: 16; color: netActive ? pywal.blue : pywal.grey; anchors.horizontalCenter: parent.horizontalCenter }
                                Text { text: btIcon; font.pixelSize: 16; color: btActive ? pywal.blue : pywal.grey; anchors.horizontalCenter: parent.horizontalCenter }
                            }
                            MouseArea { anchors.fill: parent; onClicked: dashboard.open() }
                        }
                        Rectangle {
                            anchors.horizontalCenter: parent.horizontalCenter
                            implicitWidth: 36; implicitHeight: 155; radius: 18; color: pywal.surface
                            Column {
                                anchors.centerIn: parent; spacing: 12
                                Column {
                                    anchors.horizontalCenter: parent.horizontalCenter; spacing: 0
                                    Text { text: battIcon; font.pixelSize: 16; color: battState === 4 ? pywal.green : (battState === 1 ? pywal.green : (battState === 2 ? pywal.yellow : pywal.red)); anchors.horizontalCenter: parent.horizontalCenter }
                                    Text { text: battPerc; font.pixelSize: 13; font.bold: true; color: pywal.blue; anchors.horizontalCenter: parent.horizontalCenter }
                                }
                                Column {
                                    anchors.horizontalCenter: parent.horizontalCenter; spacing: 0
                                    Text { text: volIcon; font.pixelSize: 16; color: pywal.blue; anchors.horizontalCenter: parent.horizontalCenter }
                                    Text { text: volPerc; font.pixelSize: 13; font.bold: true; color: pywal.blue; anchors.horizontalCenter: parent.horizontalCenter }
                                }
                                Column {
                                    anchors.horizontalCenter: parent.horizontalCenter; spacing: 0
                                    Text { text: "󰃠"; font.pixelSize: 16; color: pywal.yellow; anchors.horizontalCenter: parent.horizontalCenter }
                                    Text { text: brightPerc; font.pixelSize: 13; font.bold: true; color: pywal.blue; anchors.horizontalCenter: parent.horizontalCenter }
                                }
                            }
                            MouseArea { anchors.fill: parent; onClicked: dashboard.open() }
                        }
                        Item {
                            anchors.horizontalCenter: parent.horizontalCenter; implicitWidth: 34; implicitHeight: 34; Layout.bottomMargin: 8
                            Text { anchors.centerIn: parent; text: "󰐥"; color: "#f7768e"; font.pixelSize: 22; opacity: pwrMouse.containsMouse ? 0.7 : 1.0; Behavior on opacity { NumberAnimation { duration: 150 } } }
                            MouseArea { id: pwrMouse; anchors.fill: parent; hoverEnabled: true;
                                onClicked: {
                                    //Reset the process state so clicking it multiple times always works
                                    powermenuProcess.running = false;
                                    powermenuProcess.running = true;
                                }
                            }
                        }
                    }
                }
            }

            Dashboard {
                id: dashboard
                colors: pywal
                runner: commandRunner
                netActive: window.netActive
                netIcon: window.netIcon
                netStatus: window.netStatus
                btActive: window.btActive
                btIcon: window.btIcon
                vol: window.volPerc
                bright: window.brightPerc
            }
        }
    }
}
