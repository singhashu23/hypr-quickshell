import QtQuick
import qs

// Rounded container every bar module sits in, so spacing/rounding stay uniform.
Rectangle {
    id: root

    default property alias content: layout.data
    property color accent: Theme.text
    property bool hoverable: true
    signal clicked(var mouse)
    signal wheel(int delta)

    implicitWidth: layout.implicitWidth + Theme.padding * 2
    implicitHeight: Theme.barHeight - Theme.barMargin * 2
    radius: Theme.radius
    color: mouse.containsMouse && hoverable ? Theme.surface1 : Theme.surface0

    Behavior on color { ColorAnimation { duration: Theme.animFast } }

    Row {
        id: layout
        anchors.centerIn: parent
        spacing: Theme.gap
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        onClicked: mouse => root.clicked(mouse)
        onWheel: wheel => root.wheel(wheel.angleDelta.y)
    }
}
