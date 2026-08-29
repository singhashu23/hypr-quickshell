import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import qs
import qs.services

// Control centre: a sidebar of tabs over one island, in the shape noctalia
// uses. Panes are loaded on demand rather than all at once, so only the tab
// you are looking at is polling anything.
PanelWindow {
    id: root

    property bool active: false
    property int tab: 0

    readonly property var tabs: [
        { glyph: "󰋜", name: "Home",          file: "HomePane.qml" },
        { glyph: "󰕾", name: "Audio",         file: "AudioPane.qml" },
        { glyph: "󰤨", name: "Network",       file: "NetworkPane.qml" },
        { glyph: "󰂯", name: "Bluetooth",     file: "BluetoothPane.qml" },
        { glyph: "󰃞", name: "Display",       file: "DisplayPane.qml" },
        { glyph: "󰁹", name: "Power",         file: "PowerPane.qml" },
        { glyph: "󰍛", name: "System",        file: "SystemPane.qml" },
        { glyph: "󰂚", name: "Notifications", file: "NotificationsPane.qml" }
    ]

    function open()   { active = true; keys.forceActiveFocus() }
    function close()  { active = false }
    function toggle() { active ? close() : open() }
    function show(i)  { tab = Math.max(0, Math.min(i, tabs.length - 1)); open() }

    visible: active
    color: "transparent"
    anchors { top: true; bottom: true; left: true; right: true }

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: active ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    WlrLayershell.namespace: "qs-controlcenter"

    IpcHandler {
        target: "controlcenter"
        function toggle(): void { root.toggle() }
        function open(): void { root.open() }
        function close(): void { root.close() }
        function tab(index: int): void { root.show(index) }
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
        Keys.onUpPressed:   root.tab = (root.tab - 1 + root.tabs.length) % root.tabs.length
        Keys.onDownPressed: root.tab = (root.tab + 1) % root.tabs.length
    }

    Rectangle {
        id: card
        width: 880
        height: 620
        x: Math.round(parent.width - width - Theme.barMargin)
        y: Theme.barMargin
        radius: Theme.radius + 4
        color: Theme.island
        border.width: Theme.borderWidth
        border.color: Theme.border
        clip: true

        opacity: root.active ? 1 : 0
        scale: root.active ? 1 : 0.97
        transformOrigin: Item.TopRight
        Behavior on opacity { NumberAnimation { duration: Theme.animNormal; easing.type: Theme.easing } }
        Behavior on scale   { NumberAnimation { duration: Theme.animNormal; easing.type: Theme.easing } }

        MouseArea { anchors.fill: parent }

        // ---------------- sidebar ----------------
        Item {
            id: sidebar
            anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
            width: 196

            Column {
                anchors { left: parent.left; right: parent.right; top: parent.top
                          margins: Theme.gap; topMargin: Theme.gap }
                spacing: 2

                Repeater {
                    model: root.tabs

                    delegate: Rectangle {
                        required property var modelData
                        required property int index

                        width: parent.width
                        height: 44
                        radius: Theme.radiusSmall
                        color: index === root.tab ? Theme.selection
                             : tabHover.hovered ? Theme.surface0 : "transparent"
                        border.width: Theme.borderWidth
                        border.color: index === root.tab ? Theme.selectionBorder : "transparent"

                        Behavior on color { ColorAnimation { duration: Theme.animFast } }

                        HoverHandler { id: tabHover }
                        TapHandler { onTapped: root.tab = index }

                        Text {
                            id: tabGlyph
                            anchors { left: parent.left; leftMargin: Theme.padding
                                      verticalCenter: parent.verticalCenter }
                            width: 24
                            text: modelData.glyph
                            color: index === root.tab ? Theme.accent : Theme.overlay
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeLarge
                        }
                        Text {
                            anchors { left: tabGlyph.right; leftMargin: 6
                                      right: parent.right; rightMargin: Theme.gap
                                      verticalCenter: parent.verticalCenter }
                            text: modelData.name
                            color: index === root.tab ? Theme.text : Theme.subtext
                            elide: Text.ElideRight
                            font.family: Theme.uiFont
                            font.pixelSize: Theme.fontSize
                        }
                    }
                }
            }

            // session actions, the way noctalia keeps them in the header
            Rectangle {
                anchors { left: parent.left; right: parent.right; bottom: parent.bottom
                          margins: Theme.gap }
                height: 44
                radius: Theme.radiusSmall
                color: powerHover.hovered ? Theme.surface1 : Theme.surface0
                border.width: Theme.borderWidth
                border.color: Theme.border

                Behavior on color { ColorAnimation { duration: Theme.animFast } }

                HoverHandler { id: powerHover }
                TapHandler {
                    onTapped: {
                        root.close()
                        Quickshell.execDetached(["qs", "-c", "hyprland",
                                                 "ipc", "call", "powermenu", "toggle"])
                    }
                }

                Row {
                    anchors.centerIn: parent
                    spacing: 8
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "󰐥"
                        color: Theme.red
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeLarge
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Session"
                        color: Theme.text
                        font.family: Theme.uiFont
                        font.pixelSize: Theme.fontSize
                    }
                }
            }

            Rectangle {
                anchors { right: parent.right; top: parent.top; bottom: parent.bottom
                          topMargin: Theme.padding; bottomMargin: Theme.padding }
                width: 1
                color: Theme.border
            }
        }

        // ---------------- pane ----------------
        Loader {
            id: pane
            anchors { left: sidebar.right; top: parent.top; right: parent.right; bottom: parent.bottom
                      margins: Theme.padding }
            active: root.active
            asynchronous: true
            source: "panes/" + root.tabs[root.tab].file
        }

        Text {
            anchors.centerIn: pane
            visible: pane.status === Loader.Error
            text: "This pane failed to load"
            color: Theme.red
            font.family: Theme.uiFont
            font.pixelSize: Theme.fontSize
        }
    }
}
