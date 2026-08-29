import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Bluetooth
import Quickshell.Services.Mpris
import Quickshell.Services.Pipewire
import qs
import qs.services
import qs.modules.controlcenter

Column {
    id: root
    spacing: Theme.gap

    // ---- audio ----
    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var snd: sink ? sink.audio : null
    PwObjectTracker { objects: root.sink ? [root.sink] : [] }

    // ---- media ----
    readonly property var player: Mpris.players.values.find(p => p.isPlaying)
                               ?? Mpris.players.values[0] ?? null

    // ---- wifi ----
    property bool wifiOn: false
    Process {
        id: wifiState
        running: true
        command: ["sh", "-c", "nmcli -t radio wifi"]
        stdout: StdioCollector { onStreamFinished: root.wifiOn = text.trim() === "enabled" }
    }
    Process { id: wifiSet }
    Timer { interval: 4000; running: true; repeat: true; onTriggered: wifiState.running = true }

    // ---- brightness ----
    property int bright: 0
    Process {
        id: brRead
        running: true
        command: ["sh", "-c", "brightnessctl -m | cut -d, -f4 | tr -d '%'"]
        stdout: StdioCollector {
            onStreamFinished: { const v = parseInt(text.trim()); if (!isNaN(v)) root.bright = v }
        }
    }
    Process { id: brSet }

    // ---------------- who, and when ----------------
    CcSection {
        Row {
            spacing: Theme.padding

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: 54; height: 54; radius: 27
                color: Theme.selection
                border.width: Theme.borderWidth
                border.color: Theme.selectionBorder
                Text {
                    anchors.centerIn: parent
                    text: (Quickshell.env("USER") ?? "?").slice(0, 1).toUpperCase()
                    color: Theme.accent
                    font.family: Theme.uiFont
                    font.pixelSize: 24
                    font.weight: Font.Medium
                }
            }

            Column {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 2
                Text {
                    text: Quickshell.env("USER") ?? ""
                    color: Theme.text
                    font.family: Theme.uiFont
                    font.pixelSize: Theme.fontSizeLarge
                    font.weight: Font.Medium
                }
                Text {
                    text: Qt.formatDateTime(clock.date, "dddd, d MMMM · HH:mm")
                    color: Theme.subtext
                    font.family: Theme.uiFont
                    font.pixelSize: Theme.fontSize
                }
                SystemClock { id: clock; precision: SystemClock.Minutes }
            }
        }
    }

    // ---------------- quick toggles ----------------
    CcSection {
        title: "Quick settings"

        Grid {
            width: parent.width
            columns: 4
            columnSpacing: Theme.gap
            rowSpacing: Theme.gap

            property real cell: (width - columnSpacing * 3) / 4

            CcToggle {
                width: parent.cell; height: 84
                icon: root.wifiOn ? "󰤨" : "󰤮"
                name: "Wi-Fi"
                state: root.wifiOn ? "On" : "Off"
                on: root.wifiOn
                onToggled: {
                    wifiSet.command = ["nmcli", "radio", "wifi", root.wifiOn ? "off" : "on"]
                    wifiSet.running = true
                    root.wifiOn = !root.wifiOn
                }
            }

            CcToggle {
                width: parent.cell; height: 84
                readonly property var ad: Bluetooth.defaultAdapter
                icon: ad && ad.enabled ? "󰂯" : "󰂲"
                name: "Bluetooth"
                state: !ad ? "No adapter" : ad.enabled ? "On" : "Off"
                on: ad ? ad.enabled : false
                onToggled: if (ad) ad.enabled = !ad.enabled
            }

            CcToggle {
                width: parent.cell; height: 84
                icon: root.snd && root.snd.muted ? "󰝟" : "󰕾"
                name: "Sound"
                state: !root.snd ? "—" : root.snd.muted ? "Muted"
                     : Math.round(root.snd.volume * 100) + "%"
                on: root.snd ? !root.snd.muted : false
                onToggled: if (root.snd) root.snd.muted = !root.snd.muted
            }

            CcToggle {
                width: parent.cell; height: 84
                icon: Notifs.dnd ? "󰂛" : "󰂚"
                name: "Do not disturb"
                state: Notifs.dnd ? "Silenced" : "Notifying"
                on: Notifs.dnd
                onToggled: Notifs.dnd = !Notifs.dnd
            }
        }
    }

    // ---------------- the two sliders worth having up front ----------------
    CcSection {
        title: "Levels"

        CcSlider {
            icon: root.snd && root.snd.muted ? "󰝟" : "󰕾"
            value: root.snd ? root.snd.volume : 0
            enabled: root.snd !== null
            accent: Theme.teal
            onMoved: v => { if (root.snd) root.snd.volume = v }
        }

        CcSlider {
            icon: "󰃞"
            value: root.bright / 100
            onMoved: v => {
                root.bright = Math.round(Math.max(1, Math.min(100, v * 100)))
                brSet.command = ["brightnessctl", "-q", "set", root.bright + "%"]
                brSet.running = true
            }
        }
    }

    // ---------------- what is playing ----------------
    CcSection {
        title: "Media"
        visible: root.player !== null

        Row {
            width: parent.width
            spacing: Theme.padding

            Column {
                width: parent.width - 140
                anchors.verticalCenter: parent.verticalCenter
                spacing: 2
                Text {
                    width: parent.width
                    text: root.player ? (root.player.trackTitle ?? "") : ""
                    color: Theme.text
                    elide: Text.ElideRight
                    font.family: Theme.uiFont
                    font.pixelSize: Theme.fontSize + 1
                }
                Text {
                    width: parent.width
                    text: root.player ? (root.player.trackArtist ?? "") : ""
                    color: Theme.overlay
                    elide: Text.ElideRight
                    font.family: Theme.uiFont
                    font.pixelSize: Theme.fontSize - 1
                }
            }

            Row {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 4

                Repeater {
                    model: [
                        { g: "󰒮", act: "prev" },
                        { g: root.player && root.player.isPlaying ? "󰏤" : "󰐊", act: "play" },
                        { g: "󰒭", act: "next" }
                    ]
                    delegate: Rectangle {
                        required property var modelData
                        width: 40; height: 40; radius: 20
                        color: mh.hovered ? Theme.surface2 : Theme.surface1
                        Behavior on color { ColorAnimation { duration: Theme.animFast } }
                        HoverHandler { id: mh }
                        TapHandler {
                            onTapped: {
                                const p = root.player
                                if (!p) return
                                if (modelData.act === "play" && p.canTogglePlaying) p.togglePlaying()
                                else if (modelData.act === "next" && p.canGoNext) p.next()
                                else if (modelData.act === "prev" && p.canGoPrevious) p.previous()
                            }
                        }
                        Text {
                            anchors.centerIn: parent
                            text: modelData.g
                            color: Theme.text
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeLarge
                        }
                    }
                }
            }
        }
    }
}
