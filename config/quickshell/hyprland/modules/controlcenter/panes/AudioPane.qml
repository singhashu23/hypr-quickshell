import QtQuick
import Quickshell
import Quickshell.Services.Pipewire
import qs
import qs.modules.controlcenter

Column {
    id: root
    spacing: Theme.gap

    readonly property var sinks: Pipewire.nodes.values.filter(n => n.isSink && !n.isStream)
    readonly property var sources: Pipewire.nodes.values.filter(n => !n.isSink && !n.isStream && n.audio)
    readonly property var streams: Pipewire.nodes.values.filter(n => n.isStream && n.isSink)

    // volumes stay live only for nodes something is actually tracking
    PwObjectTracker { objects: root.sinks.concat(root.sources).concat(root.streams) }

    function label(n) {
        return (n.description && n.description !== "") ? n.description
             : (n.nickname && n.nickname !== "") ? n.nickname : n.name
    }

    CcSection {
        title: "Output"

        CcSlider {
            icon: Pipewire.defaultAudioSink && Pipewire.defaultAudioSink.audio
                  && Pipewire.defaultAudioSink.audio.muted ? "󰝟" : "󰕾"
            accent: Theme.teal
            enabled: Pipewire.defaultAudioSink !== null
            value: Pipewire.defaultAudioSink && Pipewire.defaultAudioSink.audio
                 ? Pipewire.defaultAudioSink.audio.volume : 0
            onMoved: v => {
                const s = Pipewire.defaultAudioSink
                if (s && s.audio) s.audio.volume = v
            }
        }

        Repeater {
            model: root.sinks
            delegate: CcRow {
                required property var modelData
                readonly property bool isDefault: Pipewire.defaultAudioSink === modelData
                icon: isDefault ? "󰓃" : "󰐖"
                title: root.label(modelData)
                subtitle: isDefault ? "Default output" : "Click to use"
                selected: isDefault
                onActivated: Pipewire.preferredDefaultAudioSink = modelData
            }
        }

        Text {
            visible: root.sinks.length === 0
            text: "No outputs reported by pipewire"
            color: Theme.overlay
            font.family: Theme.uiFont
            font.pixelSize: Theme.fontSize - 1
        }
    }

    CcSection {
        title: "Input"

        CcSlider {
            icon: Pipewire.defaultAudioSource && Pipewire.defaultAudioSource.audio
                  && Pipewire.defaultAudioSource.audio.muted ? "󰍭" : "󰍬"
            accent: Theme.sky
            enabled: Pipewire.defaultAudioSource !== null
            value: Pipewire.defaultAudioSource && Pipewire.defaultAudioSource.audio
                 ? Pipewire.defaultAudioSource.audio.volume : 0
            onMoved: v => {
                const s = Pipewire.defaultAudioSource
                if (s && s.audio) s.audio.volume = v
            }
        }

        Repeater {
            model: root.sources
            delegate: CcRow {
                required property var modelData
                readonly property bool isDefault: Pipewire.defaultAudioSource === modelData
                icon: isDefault ? "󰍬" : "󰢳"
                title: root.label(modelData)
                subtitle: isDefault ? "Default input" : "Click to use"
                selected: isDefault
                onActivated: Pipewire.preferredDefaultAudioSource = modelData
            }
        }
    }

    CcSection {
        title: "Applications"
        visible: root.streams.length > 0

        Repeater {
            model: root.streams
            delegate: Column {
                required property var modelData
                width: parent.width
                spacing: 2

                Text {
                    text: root.label(modelData)
                    color: Theme.text
                    elide: Text.ElideRight
                    width: parent.width
                    font.family: Theme.uiFont
                    font.pixelSize: Theme.fontSize
                }
                CcSlider {
                    icon: modelData.audio && modelData.audio.muted ? "󰝟" : "󰕾"
                    value: modelData.audio ? modelData.audio.volume : 0
                    enabled: modelData.audio !== null
                    onMoved: v => { if (modelData.audio) modelData.audio.volume = v }
                }
            }
        }
    }
}
