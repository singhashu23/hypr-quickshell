import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import qs

Row {
    id: root
    spacing: Theme.gap
    visible: SystemTray.items.values.length > 0

    Repeater {
        model: SystemTray.items

        delegate: MouseArea {
            required property SystemTrayItem modelData
            implicitWidth: Theme.fontSize + 6
            implicitHeight: Theme.barHeight - Theme.barMargin * 2
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton | Qt.RightButton

            onClicked: mouse => {
                if (mouse.button === Qt.LeftButton) modelData.activate()
                else modelData.secondaryActivate()
            }

            IconImage {
                anchors.centerIn: parent
                width: Theme.fontSize + 3
                height: width
                source: parent.modelData.icon
            }
        }
    }
}
