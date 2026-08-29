import QtQuick
import qs

// A titled slab inside a pane. Everything in the control centre sits in one.
Rectangle {
    id: root
    default property alias content: body.data
    property string title: ""
    property int spacing: Theme.gap

    width: parent ? parent.width : 0
    implicitHeight: (title !== "" ? head.height + 6 : 0) + body.implicitHeight + Theme.padding * 2
    height: implicitHeight
    radius: Theme.radius
    color: Theme.surface0
    border.width: Theme.borderWidth
    border.color: Theme.border

    Text {
        id: head
        visible: root.title !== ""
        anchors { top: parent.top; left: parent.left; right: parent.right
                  topMargin: Theme.padding; leftMargin: Theme.padding; rightMargin: Theme.padding }
        text: root.title
        color: Theme.overlay
        font.family: Theme.uiFont
        font.pixelSize: Theme.fontSize - 1
        font.capitalization: Font.AllUppercase
        font.letterSpacing: 0.8
    }

    Column {
        id: body
        anchors {
            top: root.title !== "" ? head.bottom : parent.top
            topMargin: root.title !== "" ? 6 : Theme.padding
            left: parent.left; right: parent.right; leftMargin: Theme.padding; rightMargin: Theme.padding
        }
        spacing: root.spacing
    }
}
