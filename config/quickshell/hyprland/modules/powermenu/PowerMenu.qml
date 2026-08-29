import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import qs
import qs.services

// Session actions, replacing the rofi powermenu that SUPER+Q used to open.
// Same island, same motion as the bar and the launcher.
PanelWindow {
    id: root

    property bool active: false
    property int index: 0

    readonly property var actions: [
        { glyph: "󰌾", name: "Lock",     // reuse the script, so this inherits
                                        // its fallback to swaylock
          run: ["waylandLockscreen"] },
        { glyph: "󰍃", name: "Log out",  run: ["hyprctl", "dispatch", "exit"] },
        { glyph: "󰤄", name: "Suspend",  run: ["systemctl", "suspend"] },
        { glyph: "󰜉", name: "Restart",  run: ["systemctl", "reboot"] },
        { glyph: "󰐥", name: "Shut down", run: ["systemctl", "poweroff"] }
    ]

    function open()   { index = 0; active = true; keys.forceActiveFocus() }
    function close()  { active = false }
    function toggle() { active ? close() : open() }

    function run() {
        const a = actions[Math.max(0, Math.min(index, actions.length - 1))]
        close()
        Quickshell.execDetached(a.run)
    }

    visible: active
    color: "transparent"
    anchors { top: true; bottom: true; left: true; right: true }

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: active ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    WlrLayershell.namespace: "qs-powermenu"

    IpcHandler {
        target: "powermenu"
        function toggle(): void { root.toggle() }
        function open(): void { root.open() }
        function close(): void { root.close() }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.close()
    }

    Item {
        id: keys
        anchors.fill: parent
        focus: true
        Keys.onEscapePressed: root.close()
        Keys.onReturnPressed: root.run()
        Keys.onEnterPressed: root.run()
        Keys.onLeftPressed:  root.index = (root.index - 1 + root.actions.length) % root.actions.length
        Keys.onRightPressed: root.index = (root.index + 1) % root.actions.length
    }

    Rectangle {
        id: card
        x: Math.round((parent.width - width) / 2)
        y: Math.round((parent.height - height) / 2)
        width: row.width + Theme.padding * 2
        height: row.height + Theme.padding * 2
        radius: Theme.radius + 4
        color: Theme.island
        border.width: Theme.borderWidth
        border.color: Theme.border

        opacity: root.active ? 1 : 0
        scale: root.active ? 1 : 0.97
        Behavior on opacity { NumberAnimation { duration: Theme.animNormal; easing.type: Theme.easing } }
        Behavior on scale   { NumberAnimation { duration: Theme.animNormal; easing.type: Theme.easing } }

        MouseArea { anchors.fill: parent }

        Row {
            id: row
            anchors.centerIn: parent
            spacing: Theme.gap

            Repeater {
                model: root.actions

                delegate: Rectangle {
                    required property var modelData
                    required property int index

                    width: 132
                    height: 132
                    radius: Theme.radius
                    color: index === root.index ? Theme.selection
                         : hover.hovered ? Theme.surface0 : "transparent"
                    border.width: Theme.borderWidth
                    border.color: index === root.index ? Theme.selectionBorder : "transparent"

                    Behavior on color { ColorAnimation { duration: Theme.animFast } }

                    HoverHandler {
                        id: hover
                        onHoveredChanged: if (hovered) root.index = index
                    }
                    TapHandler { onTapped: { root.index = index; root.run() } }

                    Column {
                        anchors.centerIn: parent
                        spacing: 10

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: modelData.glyph
                            color: index === root.index ? Theme.accent : Theme.text
                            font.family: Theme.fontFamily
                            font.pixelSize: 40
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: modelData.name
                            color: index === root.index ? Theme.text : Theme.overlay
                            font.family: Theme.uiFont
                            font.pixelSize: Theme.fontSize
                        }
                    }
                }
            }
        }
    }
}
