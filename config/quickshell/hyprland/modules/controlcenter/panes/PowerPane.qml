import QtQuick
import Quickshell
import Quickshell.Services.UPower
import qs
import qs.modules.controlcenter

Column {
    id: root
    spacing: Theme.gap

    readonly property var dev: UPower.displayDevice
    readonly property bool has: dev !== null && dev.isLaptopBattery
    readonly property int pct: dev ? Math.round(dev.percentage * 100) : 0
    readonly property bool charging: dev && dev.state === UPowerDeviceState.Charging

    function hhmm(seconds) {
        if (!seconds || seconds <= 0) return "—"
        const h = Math.floor(seconds / 3600), m = Math.floor((seconds % 3600) / 60)
        return h > 0 ? h + "h " + m + "m" : m + "m"
    }

    CcSection {
        title: "Battery"

        Row {
            spacing: Theme.padding

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: root.charging ? "󰂄"
                    : root.pct > 80 ? "󰁹" : root.pct > 60 ? "󰂀"
                    : root.pct > 40 ? "󰁾" : root.pct > 20 ? "󰁼" : "󰁺"
                color: root.charging ? Theme.green
                     : root.pct <= 20 ? Theme.red : Theme.text
                font.family: Theme.fontFamily
                font.pixelSize: 40
            }

            Column {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 2
                Text {
                    text: root.has ? root.pct + "%" : "No battery"
                    color: Theme.text
                    font.family: Theme.uiFont
                    font.pixelSize: 30
                    font.weight: Font.Medium
                }
                Text {
                    text: !root.has ? "This machine reports no laptop battery"
                        : root.charging ? "Charging · " + root.hhmm(root.dev.timeToFull) + " to full"
                        : root.hhmm(root.dev.timeToEmpty) + " remaining"
                    color: Theme.subtext
                    font.family: Theme.uiFont
                    font.pixelSize: Theme.fontSize
                }
            }
        }

        Rectangle {
            width: parent.width
            height: 8
            radius: 4
            color: Theme.surface2
            visible: root.has

            Rectangle {
                anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
                width: Math.max(8, parent.width * root.pct / 100)
                radius: 4
                color: root.charging ? Theme.green : root.pct <= 20 ? Theme.red : Theme.accent
                Behavior on width { NumberAnimation { duration: Theme.animNormal } }
            }
        }
    }

    CcSection {
        title: "Details"
        visible: root.has

        CcRow {
            icon: "󰁽"; title: "State"; interactive: false
            subtitle: root.dev ? String(root.dev.state).replace(/^UPowerDeviceState\./, "") : "—"
        }
        CcRow {
            icon: "󰚥"; title: "Health"; interactive: false
            subtitle: root.dev && root.dev.healthSupported
                    ? Math.round(root.dev.healthPercentage) + "%" : "not reported"
        }
        CcRow {
            icon: "󱐋"; title: "Rate"; interactive: false
            subtitle: root.dev ? Math.abs(root.dev.changeRate).toFixed(1) + " W" : "—"
        }
    }
}
