import QtQuick
import qs

// Icon, track, value. Dragging and clicking both seek; the wheel steps.
Item {
    id: root
    property string icon: ""
    property real value: 0          // 0..1
    property string readout: Math.round(value * 100) + "%"
    property color accent: Theme.accent
    property bool enabled: true
    signal moved(real v)

    width: parent ? parent.width : 0
    height: 34

    Text {
        id: glyph
        anchors { left: parent.left; verticalCenter: parent.verticalCenter }
        width: 24
        text: root.icon
        color: root.enabled ? root.accent : Theme.overlay
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSizeLarge
    }

    Text {
        id: val
        anchors { right: parent.right; verticalCenter: parent.verticalCenter }
        text: root.readout
        color: Theme.subtext
        font.family: Theme.uiFont
        font.pixelSize: Theme.fontSize - 1
        horizontalAlignment: Text.AlignRight
        width: 46
    }

    Item {
        id: track
        anchors { left: glyph.right; leftMargin: Theme.gap
                  right: val.left; rightMargin: Theme.gap
                  verticalCenter: parent.verticalCenter }
        height: 22

        Rectangle {
            anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter }
            height: 6
            radius: 3
            color: Theme.surface2

            Rectangle {
                anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
                width: Math.max(6, parent.width * Math.max(0, Math.min(1, root.value)))
                radius: 3
                color: root.enabled ? root.accent : Theme.overlay
                Behavior on width { NumberAnimation { duration: Theme.animFast } }
            }
        }

        Rectangle {
            x: Math.max(0, Math.min(track.width - width,
                        track.width * Math.max(0, Math.min(1, root.value)) - width / 2))
            anchors.verticalCenter: parent.verticalCenter
            width: 14; height: 14; radius: 7
            color: root.enabled ? root.accent : Theme.overlay
            border.width: 2
            border.color: Theme.island
            Behavior on x { NumberAnimation { duration: Theme.animFast } }
        }

        MouseArea {
            anchors.fill: parent
            enabled: root.enabled
            function seek(mx) { root.moved(Math.max(0, Math.min(1, mx / width))) }
            onPressed: mouse => seek(mouse.x)
            onPositionChanged: mouse => { if (pressed) seek(mouse.x) }
            onWheel: wheel => root.moved(Math.max(0, Math.min(1,
                        root.value + (wheel.angleDelta.y > 0 ? 0.05 : -0.05))))
        }
    }
}
