import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs

// Workspace pills. Under a non-Hyprland compositor Hyprland.workspaces is empty
// and this collapses to nothing rather than erroring.
Row {
    id: root
    required property var screenName
    spacing: Theme.gap / 2

    Repeater {
        model: ScriptModel {
            // only workspaces on this monitor, sorted by id
            values: [...Hyprland.workspaces.values]
                .filter(ws => !ws.monitor || ws.monitor.name === root.screenName)
                .sort((a, b) => a.id - b.id)
        }

        delegate: Rectangle {
            id: chip
            required property var modelData
            readonly property bool isActive: modelData.focused

            implicitWidth: isActive ? 32 : 24
            implicitHeight: Theme.barHeight - Theme.barMargin * 2
            radius: Theme.radius
            color: isActive ? Theme.accent
                 : modelData.urgent ? Theme.red
                 : ma.containsMouse ? Theme.surface1
                 : Theme.surface0

            Behavior on implicitWidth { NumberAnimation { duration: Theme.animNormal; easing.type: Easing.OutCubic } }
            Behavior on color { ColorAnimation { duration: Theme.animFast } }

            Text {
                anchors.centerIn: parent
                text: chip.modelData.name
                color: chip.isActive ? Theme.crust : Theme.subtext
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize
                font.bold: chip.isActive
            }

            MouseArea {
                id: ma
                anchors.fill: parent
                hoverEnabled: true
                onClicked: Hyprland.dispatch("workspace " + chip.modelData.id)
            }
        }
    }
}
