import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQml.Models
import Quickshell
import Quickshell.Wayland
import Quickshell.Io

ShellRoot {
    id: root

    // Tracks keyboard/mouse selection
    property int selectedIndex: 0

    Timer {
        id: exitTimer
        interval: 150
        onTriggered: Qt.quit()
    }

    function executeCommand(cmd) {
        execProcess.run(cmd);
        powerWindow.visible = false;
        exitTimer.start();
    }

    // --- PYWAL ENGINE ---
    QtObject {
        id: pywal
        property color bg: "#1e1e2e"
        property color fg: "#cdd6f4"
        property color surface: "#313244"
        property color border: "#45475a"
        property color accent: "#89b4fa"
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
                pywal.surface = Qt.lighter(wal.special.background, 1.5);
                pywal.border = wal.colors.color8;
                pywal.accent = wal.colors.color4;
            } catch(e) {}
        }}
    }

    // --- POWER OPTIONS MODEL ---
    ListModel {
        id: powerModel
        ListElement { name: "Lock"; icon: ""; exec: "loginctl lock-session" }
        ListElement { name: "Logout"; icon: ""; exec: "niri msg action quit" }
        ListElement { name: "Suspend"; icon: ""; exec: "systemctl suspend" }
        ListElement { name: "Reboot"; icon: ""; exec: "systemctl reboot" }
        ListElement { name: "Shutdown"; icon: ""; exec: "systemctl poweroff" }
    }

    PanelWindow {
        id: powerWindow
        screen: Quickshell.focusedScreen

        WlrLayershell.layer: WlrLayershell.Overlay
        WlrLayershell.namespace: "quickshell-powermenu"
        WlrLayershell.keyboardFocus: WlrLayershell.OnDemand

        anchors { top: true; bottom: true; left: true; right: true }

        color: "#99000000" // Dims the entire screen behind the menu

        MouseArea {
            anchors.fill: parent
            onClicked: Qt.quit()
        }

        Item {
            anchors.fill: parent
            focus: true

            // KEYBOARD NAVIGATION (Now using Left/Right)
            Keys.onEscapePressed: Qt.quit()
            Keys.onLeftPressed: {
                if (root.selectedIndex > 0) root.selectedIndex--;
                else root.selectedIndex = powerModel.count - 1;
            }
            Keys.onRightPressed: {
                if (root.selectedIndex < powerModel.count - 1) root.selectedIndex++;
                else root.selectedIndex = 0;
            }
            Keys.onReturnPressed: {
                root.executeCommand(powerModel.get(root.selectedIndex).exec);
            }

            // MAIN MENU BOX
            Rectangle {
                anchors.centerIn: parent

                // Dynamic sizing based on the row contents
                width: mainLayout.implicitWidth + 40
                height: mainLayout.implicitHeight + 40

                color: pywal.bg
                radius: 24 // Extra round for a floating pill shape
                border.color: pywal.border
                border.width: 2

                MouseArea { anchors.fill: parent }

                RowLayout {
                    id: mainLayout
                    anchors.centerIn: parent
                    spacing: 15

                    Repeater {
                        model: powerModel

                        delegate: Rectangle {
                            width: 80; height: 80
                            property bool isSelected: root.selectedIndex === index

                            color: (isSelected || mouseArea.containsMouse) ? pywal.selection : "#00000000"
                            radius: 16

                            Text {
                                anchors.centerIn: parent
                                text: model.icon
                                font.pixelSize: 36 // Much larger to fill the box
                                color: (parent.isSelected || mouseArea.containsMouse) ? pywal.accent : pywal.fg
                            }

                            MouseArea {
                                id: mouseArea
                                anchors.fill: parent
                                hoverEnabled: true
                                onPositionChanged: {
                                    if (root.selectedIndex !== index) root.selectedIndex = index;
                                }
                                onClicked: root.executeCommand(model.exec)
                            }
                        }
                    }
                }
            }
        }
    }

    Process {
        id: execProcess
        function run(cmd) {
            command = ["sh", "-c", "nohup " + cmd + " >/dev/null 2>&1 &"];
            running = true;
        }
    }
}
