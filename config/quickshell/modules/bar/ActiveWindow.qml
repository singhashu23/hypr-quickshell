import QtQuick
import Quickshell
import Quickshell.Wayland
import qs

Text {
    readonly property var tl: ToplevelManager.activeToplevel

    text: tl && tl.title ? tl.title : ""
    color: Theme.subtext
    elide: Text.ElideRight
    font.family: Theme.fontFamily
    font.pixelSize: Theme.fontSize
    verticalAlignment: Text.AlignVCenter
}
