import QtQuick
import Quickshell
import Quickshell.Bluetooth
import qs
import qs.modules.controlcenter

Column {
    id: root
    spacing: Theme.gap

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property var devices: Bluetooth.devices ? Bluetooth.devices.values : []
    readonly property var paired: devices.filter(d => d.paired || d.bonded)
    readonly property var nearby: devices.filter(d => !(d.paired || d.bonded))

    function label(d) {
        return (d.deviceName && d.deviceName !== "") ? d.deviceName
             : (d.name && d.name !== "") ? d.name : d.address
    }

    CcSection {
        title: "Adapter"

        CcRow {
            icon: root.adapter && root.adapter.enabled ? "󰂯" : "󰂲"
            title: "Bluetooth"
            subtitle: !root.adapter ? "No adapter found"
                    : root.adapter.enabled ? "On" : "Off"
            selected: root.adapter ? root.adapter.enabled : false
            interactive: root.adapter !== null
            onActivated: if (root.adapter) root.adapter.enabled = !root.adapter.enabled
        }

        CcRow {
            visible: root.adapter !== null && root.adapter.enabled
            icon: "󰐷"
            title: root.adapter && root.adapter.discovering ? "Scanning…" : "Scan for devices"
            subtitle: root.nearby.length + " nearby"
            selected: root.adapter ? root.adapter.discovering : false
            onActivated: if (root.adapter) root.adapter.discovering = !root.adapter.discovering
        }
    }

    CcSection {
        title: "Paired"
        visible: root.paired.length > 0

        Repeater {
            model: root.paired
            delegate: CcRow {
                required property var modelData
                icon: modelData.connected ? "󰂱" : "󰂯"
                title: root.label(modelData)
                subtitle: (modelData.connected ? "Connected" : "Paired")
                        + (modelData.batteryAvailable
                           ? "  ·  " + Math.round(modelData.battery * 100) + "%" : "")
                selected: modelData.connected
                onActivated: modelData.connected ? modelData.disconnect() : modelData.connect()
            }
        }
    }

    CcSection {
        title: "Nearby"
        visible: root.adapter !== null && root.adapter.enabled && root.nearby.length > 0

        Repeater {
            model: root.nearby
            delegate: CcRow {
                required property var modelData
                icon: "󰂰"
                title: root.label(modelData)
                subtitle: modelData.pairing ? "Pairing…" : "Click to pair"
                onActivated: modelData.pair()
            }
        }
    }

    Text {
        visible: root.adapter !== null && !root.adapter.enabled
        text: "Turn Bluetooth on to see devices"
        color: Theme.overlay
        font.family: Theme.uiFont
        font.pixelSize: Theme.fontSize - 1
    }
}
