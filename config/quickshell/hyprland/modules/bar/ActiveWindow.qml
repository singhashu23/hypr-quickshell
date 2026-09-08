import QtQuick
import Quickshell
import Quickshell.Wayland
import qs

// The window title. Its width is the *only* animated quantity in the centre
// island: the island tracks it instantly (animateWidth: false there), so the
// slab grows and shrinks around its own centre in one motion instead of
// chasing a target that is itself still moving.
Text {
    id: root
    property real maxWidth: 400
    readonly property var tl: ToplevelManager.activeToplevel

    text: tl && tl.title ? tl.title : ""
    color: Theme.subtext
    elide: Text.ElideRight
    width: Math.max(0, Math.min(implicitWidth, maxWidth))

    // Items inside a Row may not use anchors, so match the pill height and let
    // the text centre itself in that box.
    height: Theme.barHeight - Theme.gap * 1.75

    font.family: Theme.uiFont
    font.pixelSize: Theme.fontSize
    verticalAlignment: Text.AlignVCenter
    horizontalAlignment: Text.AlignHCenter

    // Stay alive while collapsing, so an empty title eases out rather than
    // snapping the island shut.
    visible: width > 0

    Behavior on width { NumberAnimation { duration: Theme.animNormal; easing.type: Theme.easing } }
}
