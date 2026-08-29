import QtQuick
import Quickshell
import qs
import qs.services

Row {
    id: root
    required property string screenName
    spacing: Theme.gap * 0.5
    anchors.verticalCenter: parent ? parent.verticalCenter : undefined

    Repeater {
        model: ScriptModel {
            values: Compositor.workspaces.filter(w => w.output === "" || w.output === root.screenName)
        }

        delegate: Rectangle {
            id: chip
            required property var modelData
            readonly property bool isFocused: modelData.focused

            implicitWidth: isFocused ? 34 : 22
            implicitHeight: Theme.barHeight - Theme.gap * 1.75
            radius: Theme.radiusSmall

            color: isFocused ? Theme.accent
                 : modelData.urgent ? Theme.red
                 : ma.containsMouse ? Theme.surface1
                 : Theme.surface0

            Behavior on implicitWidth { NumberAnimation { duration: Theme.animNormal; easing.type: Theme.easing } }
            Behavior on color { ColorAnimation { duration: Theme.animFast } }

            Text {
                anchors.centerIn: parent
                text: chip.modelData.name
                color: chip.isFocused ? Theme.ink : Theme.subtext
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize
                font.bold: chip.isFocused
                Behavior on color { ColorAnimation { duration: Theme.animFast } }
            }

            MouseArea {
                id: ma
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: Compositor.focus(chip.modelData)
            }
        }
    }
}
