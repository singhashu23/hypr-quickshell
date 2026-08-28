import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Io

ShellRoot {
    id: root

    // --- PYWAL COLOR ENGINE ---
    QtObject {
        id: pywal
        property color bg: "#fdf6e3"
        property color fg: "#4d4d4c"
        property color surface: "#eee8d5"
        property color border: "#333333"
        property color accent: "#859900"
        property color selection: Qt.alpha(accent, 0.15)
    }

    Process {
        command: ["sh", "-c", "cat ~/.cache/wal/colors.json 2>/dev/null | tr -d '\n'"]
        running: true
        stdout: SplitParser { onRead: (line) => {
            try {
                let wal = JSON.parse(line);
                pywal.bg = wal.special.background;
                pywal.fg = wal.special.foreground;
                pywal.surface = Qt.lighter(wal.special.background, 1.2);
                pywal.border = wal.colors.color8;
                pywal.accent = wal.colors.color4;
            } catch(e) {}
        }}
    }

    // ====================================================================
    // BACKEND SYSTEMS
    // ====================================================================

    QtObject {
        id: systemBackend
        property bool wifiOn: false
        property string wifiName: "Disconnected"
        property bool btOn: false
        property int volume: 0
        property int brightness: 0

        property var poller: Timer {
            interval: 2000; running: true; repeat: true
            onTriggered: {
                wifiStatusProc.running = true;
                wifiNameProc.running = true;
                btStatusProc.running = true;
                volStatusProc.running = true;
                brightStatusProc.running = true;
            }
        }

        property var wifiStatusProc: Process {
            command: ["sh", "-c", "nmcli radio wifi"]
            running: true
            stdout: SplitParser { onRead: (l) => systemBackend.wifiOn = (l.trim() === "enabled") }
        }

        property var wifiNameProc: Process {
            command: ["sh", "-c", "NAME=$(nmcli -t -f active,ssid dev wifi | grep '^yes' | cut -d':' -f2); echo \"${NAME:-Disconnected}\""]
            running: true
            stdout: SplitParser { onRead: (l) => systemBackend.wifiName = l.trim() }
        }

        property var btStatusProc: Process {
            command: ["sh", "-c", "bluetoothctl show | grep -c 'Powered: yes'"]
            running: true
            stdout: SplitParser { onRead: (l) => systemBackend.btOn = (l.trim() === "1") }
        }

        property var volStatusProc: Process {
            command: ["sh", "-c", "pamixer --get-volume"]
            running: true
            stdout: SplitParser { onRead: (l) => systemBackend.volume = parseInt(l.trim()) }
        }

        property var brightStatusProc: Process {
            command: ["sh", "-c", "brightnessctl i | grep -oP '(?<=\\()\\d+(?=%)'"]
            running: true
            stdout: SplitParser { onRead: (l) => systemBackend.brightness = parseInt(l.trim()) }
        }

        function toggleWifi() {
            exec.run("nmcli radio wifi " + (wifiOn ? "off" : "on"));
            wifiOn = !wifiOn;
        }
        function toggleBt() {
            exec.run("bluetoothctl power " + (btOn ? "off" : "on"));
            btOn = !btOn;
        }
        function setVolume(val) {
            exec.run("pamixer --set-volume " + Math.round(val));
        }
        function setBrightness(val) {
            exec.run("brightnessctl s " + Math.round(val) + "%");
        }

        property var exec: Process {
            function run(cmd) { command = ["sh", "-c", "nohup " + cmd + " >/dev/null 2>&1 &"]; running = true; }
        }
    }

    // ====================================================================
    // UI LAYOUT
    // ====================================================================

    PanelWindow {
        id: qsWindow
        screen: Quickshell.focusedScreen
        WlrLayershell.layer: WlrLayershell.Overlay
        WlrLayershell.namespace: "quickshell-quicksettings"
        WlrLayershell.keyboardFocus: WlrLayershell.OnDemand

        anchors { top: true; bottom: true; left: true; right: true }
        color: "transparent"

        MouseArea {
            anchors.fill: parent
            onClicked: Qt.quit()
        }

        Item {
            anchors.fill: parent
            focus: true
            Keys.onEscapePressed: Qt.quit()

            Rectangle {
                id: mainBackground

                anchors {
                    bottom: parent.bottom
                    left: parent.left
                    bottomMargin: 15
                    leftMargin: 5
                }

                width: 400
                height: mainCol.implicitHeight + 40

                color: pywal.bg
                radius: 16
                border.color: pywal.border
                border.width: 2
                clip: true

                MouseArea { anchors.fill: parent }

                ColumnLayout {
                    id: mainCol
                    anchors.fill: parent
                    anchors.margins: 20
                    spacing: 20

                    // --- TOP TOGGLES GRID ---
                    GridLayout {
                        Layout.fillWidth: true
                        columns: 2
                        columnSpacing: 15
                        rowSpacing: 15

                        QuickTogglePill {
                            title: "Wi-Fi"
                            statusText: systemBackend.wifiOn ? systemBackend.wifiName : "Off"
                            iconName: systemBackend.wifiOn ? "network-wireless-connected" : "network-wireless-disconnected"
                            isActive: systemBackend.wifiOn
                            onToggled: systemBackend.toggleWifi()
                        }

                        QuickTogglePill {
                            title: "Bluetooth"
                            statusText: systemBackend.btOn ? "On" : "Off"
                            iconName: systemBackend.btOn ? "bluetooth-active" : "bluetooth-disabled"
                            isActive: systemBackend.btOn
                            onToggled: systemBackend.toggleBt()
                        }
                    }

                    // --- SLIDERS SECTION ---
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 15

                        QuickSliderRow {
                            iconName: systemBackend.volume > 60 ? "audio-volume-high" : (systemBackend.volume > 0 ? "audio-volume-medium" : "audio-volume-muted")
                            sliderValue: systemBackend.volume
                            onMoved: (val) => systemBackend.setVolume(val)
                        }

                        QuickSliderRow {
                            // FIX: Using Nerd Font text icon instead of an SVG image!
                            iconText: ""
                            sliderValue: systemBackend.brightness
                            onMoved: (val) => systemBackend.setBrightness(val)
                        }
                    }

                    // --- BOTTOM ROW (POWER MENU) ---
                    Rectangle {
                        Layout.fillWidth: true
                        height: 1
                        color: pywal.surface
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.topMargin: 5

                        // Invisible spacer pushes the power button to the right side
                        Item { Layout.fillWidth: true }

                        // Power Menu Launch Button
                        Rectangle {
                            width: 42; height: 42; radius: 10
                            color: powerMouse.containsMouse ? pywal.selection : "transparent"
                            border.color: powerMouse.containsMouse ? pywal.accent : "transparent"
                            border.width: 1

                            Text {
                                anchors.centerIn: parent
                                text: "" // Nerd Font Power Icon
                                font.pixelSize: 18
                                color: powerMouse.containsMouse ? pywal.accent : pywal.fg
                            }

                            MouseArea {
                                id: powerMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: {
                                    // Spawns your exact Powermenu and cleanly quits the quicksettings!
                                    systemBackend.exec.run("QT_QPA_PLATFORMTHEME=qt6ct quickshell -p ~/.config/quickshell/powermenu.qml");
                                    Qt.quit();
                                }
                            }
                        }
                    }
                }
            }
        }
    }


    // ====================================================================
    // REUSABLE UI COMPONENTS
    // ====================================================================

    component QuickTogglePill: Rectangle {
        property string title: "Title"
        property string statusText: "Enabled"
        property string iconName: ""
        property bool isActive: false
        signal toggled()

        Layout.fillWidth: true
        height: 60

        // FIX: Reduced border radius from 16 to 10 for a much sleeker, boxy aesthetic
        radius: 10

        color: isActive ? pywal.accent : (mouseAreaPill.containsMouse ? pywal.selection : pywal.surface)
        border.color: isActive ? pywal.border : "transparent"
        border.width: 1

        RowLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 12

            Image {
                Layout.preferredWidth: 24; Layout.preferredHeight: 24
                sourceSize.width: 24; sourceSize.height: 24
                source: "image://icon/" + iconName
                fillMode: Image.PreserveAspectFit
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0
                Text {
                    text: title; font.bold: true; font.pixelSize: 14
                    color: isActive ? pywal.bg : pywal.fg
                }
                Text {
                    text: statusText; font.pixelSize: 11
                    opacity: 0.8; color: isActive ? pywal.bg : pywal.fg
                    elide: Text.ElideRight; Layout.fillWidth: true
                }
            }
        }

        MouseArea {
            id: mouseAreaPill
            anchors.fill: parent
            hoverEnabled: true
            onClicked: parent.toggled()
        }
    }

    component QuickSliderRow: RowLayout {
        property string iconName: ""

        // FIX: Added string support for Nerd Fonts
        property string iconText: ""

        property alias sliderValue: sliderControl.value
        signal moved(real value)

        spacing: 15

        // Legacy SVG Support (Visible only if iconName is used)
        Image {
            visible: parent.iconName !== ""
            Layout.preferredWidth: 28; Layout.preferredHeight: 28
            sourceSize.width: 28; sourceSize.height: 28
            source: parent.iconName !== "" ? "image://icon/" + parent.iconName : ""
            fillMode: Image.PreserveAspectFit
        }

        // Nerd Font Support (Visible only if iconText is used)
        Text {
            visible: parent.iconText !== ""
            Layout.preferredWidth: 28
            text: parent.iconText
            font.pixelSize: 22
            color: pywal.fg
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }

        Slider {
            id: sliderControl
            Layout.fillWidth: true
            from: 0; to: 100
            onMoved: parent.moved(value)

            background: Rectangle {
                x: sliderControl.leftPadding
                y: sliderControl.topPadding + sliderControl.availableHeight / 2 - height / 2
                implicitWidth: 200; implicitHeight: 24
                width: sliderControl.availableWidth; height: implicitHeight
                radius: height/2
                color: pywal.surface

                Rectangle {
                    width: sliderControl.visualPosition * parent.width
                    height: parent.height
                    color: pywal.accent
                    radius: height/2
                }
            }

            handle: Rectangle {
                visible: false
                x: sliderControl.leftPadding + sliderControl.visualPosition * (sliderControl.availableWidth - width)
                y: sliderControl.topPadding + sliderControl.availableHeight / 2 - height / 2
                width: 0; height: 0
            }
        }
    }
}
