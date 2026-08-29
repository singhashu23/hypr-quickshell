import QtQuick
import Quickshell
import qs
import qs.services
import qs.modules.controlcenter

Column {
    id: root
    spacing: Theme.gap

    CcSection {
        title: "Delivery"

        CcRow {
            icon: Notifs.dnd ? "󰂛" : "󰂚"
            title: "Do not disturb"
            subtitle: Notifs.dnd
                    ? "Toasts suppressed — still recorded here, and critical ones still show"
                    : "Toasts shown"
            selected: Notifs.dnd
            onActivated: Notifs.dnd = !Notifs.dnd
        }

        CcRow {
            icon: "󰎟"
            title: "Clear history"
            subtitle: Notifs.history.length + " kept (newest " + Notifs.limit + ")"
            interactive: Notifs.history.length > 0
            onActivated: Notifs.clear()
        }
    }

    CcSection {
        title: "History"

        Text {
            visible: Notifs.history.length === 0
            text: "Nothing yet"
            color: Theme.overlay
            font.family: Theme.uiFont
            font.pixelSize: Theme.fontSize - 1
        }

        Repeater {
            model: Notifs.history

            delegate: Rectangle {
                required property var modelData
                width: parent.width
                height: col.implicitHeight + Theme.padding
                radius: Theme.radiusSmall
                color: "transparent"
                border.width: Theme.borderWidth
                border.color: modelData.critical ? Theme.red : Theme.border

                Column {
                    id: col
                    anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter
                              leftMargin: Theme.padding; rightMargin: Theme.padding }
                    spacing: 2

                    Text {
                        width: parent.width
                        text: (modelData.appName !== "" ? modelData.appName + "  ·  " : "")
                            + Qt.formatDateTime(modelData.at, "HH:mm")
                        color: modelData.critical ? Theme.red : Theme.overlay
                        elide: Text.ElideRight
                        font.family: Theme.uiFont
                        font.pixelSize: Theme.fontSize - 2
                    }
                    Text {
                        width: parent.width
                        visible: modelData.summary !== ""
                        text: modelData.summary
                        color: Theme.text
                        elide: Text.ElideRight
                        font.family: Theme.uiFont
                        font.pixelSize: Theme.fontSize
                    }
                    Text {
                        width: parent.width
                        visible: modelData.body !== ""
                        text: modelData.body
                        color: Theme.subtext
                        wrapMode: Text.WordWrap
                        maximumLineCount: 2
                        elide: Text.ElideRight
                        font.family: Theme.uiFont
                        font.pixelSize: Theme.fontSize - 1
                    }
                }
            }
        }
    }
}
