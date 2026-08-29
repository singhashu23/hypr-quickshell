import QtQuick
import Quickshell
import qs

// Island bar: a transparent panel carrying three separate slabs. The panel
// itself reserves the strip; the islands float inside it.
PanelWindow {
    id: bar
    required property var modelData

    screen: modelData
    color: "transparent"

    anchors { top: true; left: true; right: true }
    implicitHeight: Theme.barHeight + Theme.barMargin * 2

    Item {
        anchors.fill: parent
        anchors.margins: Theme.barMargin

        // ---- left island ----
        Island {
            anchors { left: parent.left; verticalCenter: parent.verticalCenter }
            Workspaces { screenName: bar.modelData.name }
        }

        // ---- centre island ----
        Island {
            anchors.centerIn: parent
            MediaPlayer {}
            ActiveWindow { maxWidth: bar.width * 0.30 }
        }

        // ---- right island ----
        Island {
            anchors { right: parent.right; verticalCenter: parent.verticalCenter }
            Tray {}
            Backlight {}
            Audio {}
            Network {}
            Battery {}
            Clock {}
        }
    }
}
