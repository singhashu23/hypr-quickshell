import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Notifications
import Quickshell.Io

ShellRoot {
    id: root

    // --- PYWAL COLOR ENGINE ---
    QtObject {
        id: pywal
        property color bg: "#1e1e2e"
        property color fg: "#cdd6f4"
        property color surface: "#313244"
        property color border: "#45475a"
        property color accent: "#89b4fa"
        property color red: "#f38ba8"
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
                pywal.red = wal.colors.color1;
            } catch(e) {}
        }}
    }

    // --- THE DBUS NOTIFICATION SERVER ---
    NotificationServer {
        id: server
        bodyMarkupSupported: true
        actionsSupported: true
        imageSupported: true
    }

    // --- UI LAYOUT ---
    PanelWindow {
        id: notifWindow
        screen: Quickshell.screens[0]
        WlrLayershell.layer: WlrLayershell.Overlay
        WlrLayershell.namespace: "quickshell-notifications"

        anchors { top: true; right: true }
        margins { top: 20; right: 20 }

        implicitWidth: 380
        implicitHeight: notifLayout.implicitHeight
        color: "transparent"

        ColumnLayout {
            id: notifLayout
            width: parent.width
            spacing: 15

            Repeater {
                id: notifRepeater
                model: server.trackedNotifications

                delegate: Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: contentCol.implicitHeight + 30

                    radius: 16
                    color: pywal.bg

                    border.color: model.urgency === 2 ? pywal.red : pywal.border
                    border.width: 2
                    clip: true

                    Timer {
                        interval: model.expireTimeout > 0 ? (model.expireTimeout * 1000) : 5000
                        running: true
                        onTriggered: model.expire()
                    }

                    RowLayout {
                        id: contentCol
                        anchors.fill: parent
                        anchors.margins: 15
                        spacing: 15

                        Image {
                            Layout.alignment: Qt.AlignTop
                            Layout.preferredWidth: 48
                            Layout.preferredHeight: 48

                            source: {
                                if (!model.appIcon || model.appIcon === "") return "image://icon/dialog-information";
                                if (model.appIcon.startsWith("file://")) return model.appIcon;
                                if (model.appIcon.startsWith("/")) return "file://" + model.appIcon;
                                return "image://icon/" + model.appIcon;
                            }
                            fillMode: Image.PreserveAspectFit
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignTop
                            spacing: 5

                            RowLayout {
                                Layout.fillWidth: true

                                Text {
                                    text: model.appName !== "" ? model.appName : "Notification"
                                    font.pixelSize: 12
                                    font.bold: true
                                    color: pywal.accent
                                    Layout.fillWidth: true
                                    elide: Text.ElideRight
                                }

                                Rectangle {
                                    width: 24; height: 24; radius: 12
                                    color: closeMouse.containsMouse ? pywal.selection : "transparent"

                                    Text {
                                        anchors.centerIn: parent
                                        text: ""
                                        font.pixelSize: 14
                                        color: pywal.fg
                                    }

                                    MouseArea {
                                        id: closeMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        onClicked: model.dismiss()
                                    }
                                }
                            }

                            Text {
                                text: model.summary
                                font.bold: true
                                font.pixelSize: 15
                                color: pywal.fg
                                Layout.fillWidth: true
                                wrapMode: Text.Wrap
                            }

                            Text {
                                visible: model.body !== ""
                                text: model.body
                                font.pixelSize: 13
                                color: pywal.fg
                                opacity: 0.8
                                Layout.fillWidth: true
                                wrapMode: Text.Wrap
                                textFormat: Text.StyledText
                            }
                        }
                    }
                }
            }
        }
    }
}
