import QtQuick
import Quickshell
import Quickshell.Services.Mpris
import qs

Pill {
    id: root
    readonly property var player: Mpris.players.values.find(p => p.isPlaying) ?? Mpris.players.values[0] ?? null

    visible: player !== null
    onClicked: if (player && player.canTogglePlaying) player.togglePlaying()

    IconLabel {
        icon: root.player && root.player.isPlaying ? "󰏤" : "󰐊"
        color: Theme.mauve
        label: {
            if (!root.player) return ""
            const t = root.player.trackTitle ?? ""
            const a = root.player.trackArtist ?? ""
            const s = a ? a + " — " + t : t
            return s.length > 40 ? s.slice(0, 39) + "…" : s
        }
    }
}
