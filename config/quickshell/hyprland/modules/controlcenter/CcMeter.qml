import QtQuick
import qs

// A readout, not a control. Deliberately not a disabled CcSlider: a slider
// draws a handle, and a handle says "drag me".
Item {
    id: root
    property string icon: ""
    property string label: ""
    property real value: 0          // 0..1
    property string readout: Math.round(value * 100) + "%"
    property color accent: Theme.accent

    width: parent ? parent.width : 0
    height: 40

    Text {
        id: glyph
        anchors { left: parent.left; verticalCenter: parent.verticalCenter }
        width: 24
        text: root.icon
        color: root.accent
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSizeLarge
    }

    Text {
        id: val
        anchors { right: parent.right; verticalCenter: parent.verticalCenter }
        text: root.readout
        color: Theme.subtext
        horizontalAlignment: Text.AlignRight
        width: 84
        font.family: Theme.uiFont
        font.pixelSize: Theme.fontSize - 1
    }

    Column {
        anchors { left: glyph.right; leftMargin: Theme.gap
                  right: val.left; rightMargin: Theme.gap
                  verticalCenter: parent.verticalCenter }
        spacing: 5

        Text {
            text: root.label
            color: Theme.overlay
            font.family: Theme.uiFont
            font.pixelSize: Theme.fontSize - 2
        }

        Rectangle {
            width: parent.width
            height: 6
            radius: 3
            color: Theme.surface2

            Rectangle {
                anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
                width: Math.max(3, parent.width * Math.max(0, Math.min(1, root.value)))
                radius: 3
                color: root.accent
                Behavior on width { NumberAnimation { duration: Theme.animNormal } }
            }
        }
    }
}
