import QtQuick
import Quickshell
import qs

PanelWindow {
    id: bar
    required property var modelData

    screen: modelData
    color: "transparent"

    anchors { top: true; left: true; right: true }
    implicitHeight: Theme.barHeight
    margins { left: Theme.barMargin; right: Theme.barMargin; top: Theme.barMargin }

    Rectangle {
        anchors.fill: parent
        radius: Theme.radius + 2
        color: Theme.mantle
    }

    // ---- left ----
    Row {
        anchors { left: parent.left; leftMargin: Theme.barMargin; verticalCenter: parent.verticalCenter }
        spacing: Theme.gap

        Workspaces { screenName: bar.modelData.name }
        MediaPlayer {}
    }

    // ---- center ----
    ActiveWindow {
        anchors.centerIn: parent
        width: Math.min(implicitWidth, bar.width * 0.35)
        horizontalAlignment: Text.AlignHCenter
    }

    // ---- right ----
    Row {
        anchors { right: parent.right; rightMargin: Theme.barMargin; verticalCenter: parent.verticalCenter }
        spacing: Theme.gap

        Tray {}
        Backlight {}
        Audio {}
        Network {}
        Battery {}
        Clock {}
    }
}
