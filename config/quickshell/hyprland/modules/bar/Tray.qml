import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import qs

Row {
    id: root

    // StatusNotifierItem defines Passive as "idle, may be hidden". Plenty of
    // background helpers sit there permanently (xwaylandvideobridge, for one),
    // so they are hidden unless asked for — the same default waybar uses.
    property bool showPassive: false

    spacing: Theme.gap * 0.5
    anchors.verticalCenter: parent ? parent.verticalCenter : undefined

    Repeater {
        model: ScriptModel {
            values: [...SystemTray.items.values].filter(
                i => root.showPassive || i.status !== SystemTrayItem.Passive)
        }

        delegate: Rectangle {
            id: entry
            required property SystemTrayItem modelData

            implicitWidth: Theme.barHeight - Theme.gap * 1.75
            implicitHeight: width
            radius: Theme.radiusSmall
            color: ma.containsMouse ? Theme.surface1 : "transparent"

            Behavior on color { ColorAnimation { duration: Theme.animFast } }

            Image {
                id: img
                anchors.centerIn: parent
                width: Theme.fontSize + 4
                height: width
                source: entry.modelData.icon
                sourceSize: Qt.size(64, 64)
                fillMode: Image.PreserveAspectFit
                asynchronous: true
                visible: status === Image.Ready
            }

            // Qt renders a magenta placeholder for an icon it cannot find, which
            // is louder than anything else on the bar. Show a quiet glyph instead.
            Text {
                anchors.centerIn: parent
                visible: img.status === Image.Error || img.status === Image.Null
                text: "󰘔"
                color: Theme.overlay
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize
            }

            MouseArea {
                id: ma
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                onClicked: mouse => {
                    if (mouse.button === Qt.LeftButton) entry.modelData.activate()
                    else entry.modelData.secondaryActivate()
                }
            }
        }
    }
}
