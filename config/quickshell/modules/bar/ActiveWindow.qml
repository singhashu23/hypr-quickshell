import QtQuick
import Quickshell
import Quickshell.Wayland
import qs

Text {
    id: root
    property real maxWidth: 400
    readonly property var tl: ToplevelManager.activeToplevel

    text: tl && tl.title ? tl.title : ""
    color: Theme.subtext
    elide: Text.ElideRight
    width: Math.min(implicitWidth, maxWidth)
    font.family: Theme.uiFont
    font.pixelSize: Theme.fontSize
    verticalAlignment: Text.AlignVCenter
    horizontalAlignment: Text.AlignHCenter
    anchors.verticalCenter: parent ? parent.verticalCenter : undefined
    visible: text !== ""

    Behavior on width { NumberAnimation { duration: Theme.animNormal; easing.type: Theme.easing } }
}
