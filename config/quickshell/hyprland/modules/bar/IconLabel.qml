import QtQuick
import qs

Row {
    property string icon: ""
    property string label: ""
    property color color: Theme.text

    spacing: Theme.gap
    anchors.verticalCenter: parent ? parent.verticalCenter : undefined

    Text {
        text: parent.icon
        color: parent.color
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSize + 1
        anchors.verticalCenter: parent.verticalCenter
    }
    Text {
        visible: parent.label !== ""
        text: parent.label
        color: Theme.text
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSize
        anchors.verticalCenter: parent.verticalCenter
    }
}
