import QtQuick
import Quickshell
import Quickshell.Services.Pipewire
import qs

Pill {
    id: root
    // bound reactively — the default sink is null until pipewire is ready
    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var audio: sink ? sink.audio : null
    readonly property int pct: audio ? Math.round(audio.volume * 100) : 0
    readonly property bool muted: audio ? audio.muted : true

    // keeps the sink's volume properties live
    PwObjectTracker { objects: sink ? [sink] : [] }

    visible: sink !== null

    onClicked: if (audio) audio.muted = !audio.muted
    onWheel: delta => {
        if (!audio) return
        audio.volume = Math.max(0, Math.min(1, audio.volume + (delta > 0 ? 0.05 : -0.05)))
    }

    IconLabel {
        icon: root.muted ? "󰝟" : root.pct > 66 ? "󰕾" : root.pct > 33 ? "󰖀" : "󰕿"
        color: root.muted ? Theme.overlay : Theme.teal
        label: root.muted ? "muted" : root.pct + "%"
    }
}
