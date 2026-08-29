import QtQuick
import qs

// A square quick-toggle tile: glyph, name, and a line of state under it.
Rectangle {
    id: root
    property string icon: ""
    property string name: ""
    property string state: ""
    property bool on: false
    signal toggled()

    radius: Theme.radius
    color: root.on ? Theme.selection : hover.hovered ? Theme.surface1 : Theme.surface0
    border.width: Theme.borderWidth
    border.color: root.on ? Theme.selectionBorder : Theme.border

    Behavior on color { ColorAnimation { duration: Theme.animFast } }

    HoverHandler { id: hover }
    TapHandler { onTapped: root.toggled() }

    Column {
        anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter
                  leftMargin: Theme.padding; rightMargin: Theme.padding }
        spacing: 4

        Text {
            text: root.icon
            color: root.on ? Theme.accent : Theme.overlay
            font.family: Theme.fontFamily
            font.pixelSize: 22
        }
        Text {
            width: parent.width
            text: root.name
            color: Theme.text
            elide: Text.ElideRight
            font.family: Theme.uiFont
            font.pixelSize: Theme.fontSize
        }
        Text {
            width: parent.width
            visible: root.state !== ""
            text: root.state
            color: Theme.overlay
            elide: Text.ElideRight
            font.family: Theme.uiFont
            font.pixelSize: Theme.fontSize - 2
        }
    }
}
