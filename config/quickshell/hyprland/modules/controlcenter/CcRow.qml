import QtQuick
import qs

// A list row: glyph, title, subtitle, and whatever is put on the right.
Rectangle {
    id: root
    default property alias trailing: right.data
    property string icon: ""
    property string title: ""
    property string subtitle: ""
    property bool selected: false
    property bool interactive: true
    signal activated()

    width: parent ? parent.width : 0
    height: 52
    radius: Theme.radiusSmall
    color: root.selected ? Theme.selection
         : (root.interactive && hover.hovered) ? Theme.surface1 : "transparent"
    border.width: Theme.borderWidth
    border.color: root.selected ? Theme.selectionBorder : "transparent"

    Behavior on color { ColorAnimation { duration: Theme.animFast } }

    HoverHandler { id: hover; enabled: root.interactive }
    TapHandler { enabled: root.interactive; onTapped: root.activated() }

    Text {
        id: glyph
        anchors { left: parent.left; leftMargin: Theme.padding; verticalCenter: parent.verticalCenter }
        width: 26
        text: root.icon
        color: root.selected ? Theme.accent : Theme.subtext
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSizeLarge
    }

    Item {
        id: right
        anchors { right: parent.right; rightMargin: Theme.padding; verticalCenter: parent.verticalCenter }
        implicitWidth: childrenRect.width
        implicitHeight: childrenRect.height
        width: implicitWidth
        height: implicitHeight
    }

    Column {
        anchors { left: glyph.right; leftMargin: Theme.gap
                  right: right.left; rightMargin: Theme.gap
                  verticalCenter: parent.verticalCenter }
        spacing: 1

        Text {
            width: parent.width
            text: root.title
            color: Theme.text
            elide: Text.ElideRight
            font.family: Theme.uiFont
            font.pixelSize: Theme.fontSize
        }
        Text {
            width: parent.width
            visible: root.subtitle !== ""
            text: root.subtitle
            color: Theme.overlay
            elide: Text.ElideRight
            font.family: Theme.uiFont
            font.pixelSize: Theme.fontSize - 2
        }
    }
}
