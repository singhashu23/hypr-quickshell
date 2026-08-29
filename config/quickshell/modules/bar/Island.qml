import QtQuick
import qs

// A discrete rounded slab. Islands are the shell's unit of surface: the bar is
// three of them, and popouts share the same corner, hairline and motion.
Rectangle {
    id: root
    default property alias content: layout.data
    property alias spacing: layout.spacing

    implicitWidth: layout.implicitWidth + Theme.padding * 2
    implicitHeight: Theme.barHeight

    radius: Theme.radius
    color: Theme.island
    border.width: Theme.borderWidth
    border.color: Theme.border

    visible: layout.implicitWidth > 0

    Behavior on color       { ColorAnimation { duration: Theme.animNormal } }
    Behavior on border.color { ColorAnimation { duration: Theme.animNormal } }
    Behavior on implicitWidth {
        NumberAnimation { duration: Theme.animNormal; easing.type: Theme.easing }
    }

    Row {
        id: layout
        anchors.centerIn: parent
        spacing: Theme.gap
    }
}
