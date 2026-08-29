import QtQuick
import qs

// A small action button, for the trailing edge of a row.
Rectangle {
    id: root
    property string label: ""
    property bool primary: false
    property bool busy: false
    property bool enabled: true
    signal clicked()

    implicitWidth: text.implicitWidth + Theme.padding * 2
    implicitHeight: 30
    width: implicitWidth
    height: implicitHeight
    radius: Theme.radiusSmall

    color: !root.enabled ? "transparent"
         : root.primary ? (hover.hovered ? Theme.selectionBorder : Theme.selection)
         : (hover.hovered ? Theme.surface2 : Theme.surface1)
    border.width: Theme.borderWidth
    border.color: root.primary ? Theme.selectionBorder : Theme.border
    opacity: root.enabled ? 1 : 0.45

    Behavior on color { ColorAnimation { duration: Theme.animFast } }

    HoverHandler { id: hover; enabled: root.enabled }
    TapHandler { enabled: root.enabled; onTapped: root.clicked() }

    Text {
        id: text
        anchors.centerIn: parent
        text: root.busy ? "…" : root.label
        color: root.primary ? Theme.text : Theme.subtext
        font.family: Theme.uiFont
        font.pixelSize: Theme.fontSize - 1
    }
}
