import QtQuick
import qs

// An item *inside* an island. It carries no border of its own — the island
// provides the frame — so the row reads as one surface, not a row of chips.
Rectangle {
    id: root

    default property alias content: layout.data
    property bool hoverable: true
    signal clicked(var mouse)
    signal wheel(int delta)

    implicitWidth: layout.implicitWidth + Theme.gap * 1.5
    implicitHeight: Theme.barHeight - Theme.gap * 1.75
    radius: Theme.radiusSmall
    color: mouse.containsMouse && hoverable ? Theme.surface1 : "transparent"

    Behavior on color { ColorAnimation { duration: Theme.animFast } }

    Row {
        id: layout
        anchors.centerIn: parent
        spacing: Theme.gap * 0.75
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: hoverable ? Qt.PointingHandCursor : Qt.ArrowCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        onClicked: mouse => root.clicked(mouse)
        onWheel: wheel => root.wheel(wheel.angleDelta.y)
    }
}
