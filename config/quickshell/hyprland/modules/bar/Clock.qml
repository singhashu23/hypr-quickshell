import QtQuick
import Quickshell
import qs

Pill {
    id: root
    property bool showSeconds: false

    SystemClock {
        id: clock
        precision: root.showSeconds ? SystemClock.Seconds : SystemClock.Minutes
    }

    // click toggles seconds; the tooltip-less date sits alongside the time
    onClicked: root.showSeconds = !root.showSeconds

    IconLabel {
        icon: "󰥔"
        color: Theme.blue
        label: Qt.formatDateTime(clock.date, root.showSeconds ? "ddd d MMM  hh:mm:ss" : "ddd d MMM  hh:mm")
    }
}
