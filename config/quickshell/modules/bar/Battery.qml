import QtQuick
import Quickshell
import Quickshell.Services.UPower
import qs

Pill {
    id: root
    readonly property var dev: UPower.displayDevice
    readonly property int pct: dev ? Math.round(dev.percentage * 100) : 0
    readonly property bool charging: dev && dev.state === UPowerDeviceState.Charging
    readonly property bool low: pct <= 20 && !charging

    // hidden on desktops, or before upower reports a real battery
    visible: dev !== null && dev.isLaptopBattery

    hoverable: false

    IconLabel {
        icon: root.charging ? "󰂄"
            : root.pct > 80 ? "󰁹" : root.pct > 60 ? "󰂀"
            : root.pct > 40 ? "󰁾" : root.pct > 20 ? "󰁼" : "󰁺"
        color: root.charging ? Theme.green : root.low ? Theme.red : Theme.text
        label: root.pct + "%"
    }
}
