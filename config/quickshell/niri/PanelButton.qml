import QtQuick
import QtQuick.Controls

Button {
    id: control
    implicitWidth: 40
    implicitHeight: 40

    background: Rectangle {
        // Toggle color on hover for a modern feel
        color: control.hovered ? "#24283b" : "transparent"
        radius: 10
        border.color: control.pressed ? "#7aa2f7" : "transparent"
        border.width: 1
    }

    contentItem: Text {
        text: control.text
        font.pixelSize: 22 // Optimized for Nerd Font icons
        color: control.hovered ? "#7aa2f7" : "#a9b1d6"
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }
}
