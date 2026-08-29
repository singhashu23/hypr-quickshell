import QtQuick
import Quickshell
import Quickshell.Services.Notifications
import qs

// One notification, shaped like every other island in the shell.
Rectangle {
    id: root

    required property var notif
    signal closed()

    readonly property bool critical: notif.urgency === NotificationUrgency.Critical
    readonly property bool lowUrgency: notif.urgency === NotificationUrgency.Low

    // Critical notifications stay until acknowledged — expiring them silently
    // is how you miss the one that mattered.
    readonly property int timeout: {
        if (critical) return 0
        if (notif.expireTimeout > 0) return notif.expireTimeout
        return lowUrgency ? 4000 : 6000
    }

    implicitHeight: layout.implicitHeight + Theme.padding * 2
    radius: Theme.radius
    color: Theme.island
    border.width: Theme.borderWidth
    border.color: critical ? Theme.red : Theme.border

    HoverHandler { id: hover }

    // Reading a notification should not race a timer.
    Timer {
        interval: root.timeout
        running: root.timeout > 0 && !hover.hovered
        onTriggered: root.closed()
    }

    // countdown hairline
    Rectangle {
        id: life
        visible: root.timeout > 0
        anchors { left: parent.left; bottom: parent.bottom; leftMargin: Theme.radius; bottomMargin: 1 }
        height: 2
        radius: 1
        color: root.critical ? Theme.red : Theme.accent
        opacity: 0.5
        width: root.width - Theme.radius * 2

        NumberAnimation on width {
            running: root.timeout > 0 && !hover.hovered
            from: root.width - Theme.radius * 2
            to: 0
            duration: root.timeout
        }
    }

    Row {
        id: layout
        anchors { left: parent.left; right: parent.right; top: parent.top; margins: Theme.padding }
        spacing: Theme.padding

        // notification image (album art, avatar) wins over the app icon
        Item {
            width: visible ? 44 : 0
            height: 44
            visible: icon.status === Image.Ready || fallback.visible

            Image {
                id: icon
                anchors.fill: parent
                source: {
                    const n = root.notif
                    if (n.image) return n.image
                    if (!n.appIcon) return ""
                    if (n.appIcon.startsWith("file://") || n.appIcon.startsWith("image://")) return n.appIcon
                    if (n.appIcon.startsWith("/")) return "file://" + n.appIcon
                    return "image://icon/" + n.appIcon
                }
                sourceSize: Qt.size(96, 96)
                fillMode: Image.PreserveAspectFit
                asynchronous: true
                visible: status === Image.Ready
            }

            // Qt draws a magenta placeholder for an icon it cannot resolve.
            Text {
                id: fallback
                anchors.centerIn: parent
                visible: icon.status !== Image.Ready
                text: root.critical ? "󰀪" : "󰂚"
                color: root.critical ? Theme.red : Theme.accent
                font.family: Theme.fontFamily
                font.pixelSize: 22
            }
        }

        Column {
            width: layout.width - (layout.children[0].width > 0 ? 44 + Theme.padding : 0)
            spacing: 3

            Row {
                width: parent.width
                spacing: Theme.gap

                Text {
                    width: parent.width - closeBtn.width - Theme.gap
                    text: root.notif.appName !== "" ? root.notif.appName : "Notification"
                    color: root.critical ? Theme.red : Theme.accent
                    elide: Text.ElideRight
                    font.family: Theme.uiFont
                    font.pixelSize: Theme.fontSize - 2
                    font.bold: true
                }

                Rectangle {
                    id: closeBtn
                    width: 18; height: 18; radius: 9
                    color: closeHover.hovered ? Theme.surface1 : "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: "󰅖"
                        color: Theme.overlay
                        font.family: Theme.fontFamily
                        font.pixelSize: 11
                    }
                    HoverHandler { id: closeHover }
                    TapHandler { onTapped: root.closed() }
                }
            }

            Text {
                width: parent.width
                text: root.notif.summary
                color: Theme.text
                wrapMode: Text.Wrap
                maximumLineCount: 2
                elide: Text.ElideRight
                font.family: Theme.uiFont
                font.pixelSize: Theme.fontSize + 1
            }

            Text {
                width: parent.width
                visible: root.notif.body !== ""
                text: root.notif.body
                color: Theme.subtext
                wrapMode: Text.Wrap
                maximumLineCount: 4
                elide: Text.ElideRight
                textFormat: Text.StyledText
                font.family: Theme.uiFont
                font.pixelSize: Theme.fontSize - 1
            }

            // The old daemon advertised actionsSupported but never drew them,
            // so every actionable notification was a dead end.
            Row {
                spacing: Theme.gap
                topPadding: root.notif.actions.length > 0 ? 6 : 0
                visible: root.notif.actions.length > 0

                Repeater {
                    model: root.notif.actions

                    delegate: Rectangle {
                        required property var modelData
                        implicitWidth: label.implicitWidth + Theme.padding * 1.5
                        implicitHeight: 26
                        radius: Theme.radiusSmall
                        color: actHover.hovered ? Theme.surface2 : Theme.surface0

                        Behavior on color { ColorAnimation { duration: Theme.animFast } }

                        Text {
                            id: label
                            anchors.centerIn: parent
                            text: modelData.text
                            color: Theme.text
                            font.family: Theme.uiFont
                            font.pixelSize: Theme.fontSize - 1
                        }
                        HoverHandler { id: actHover }
                        TapHandler {
                            onTapped: { modelData.invoke(); root.closed() }
                        }
                    }
                }
            }
        }
    }

    // click the body to dismiss
    TapHandler {
        onTapped: root.closed()
    }
}
