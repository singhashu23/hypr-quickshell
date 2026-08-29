pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

// One workspace interface over two compositors.
//
// Hyprland is the target, but the setup is often driven from a niri session,
// and a workspace widget that only works after logging out is a workspace
// widget you cannot check. Both back ends produce the same shape:
//   { id, name, focused, urgent, output }
Singleton {
    id: root

    // env() yields null (not "") when unset, so coerce rather than compare
    readonly property bool onHyprland: !!Quickshell.env("HYPRLAND_INSTANCE_SIGNATURE")
    readonly property string backend: onHyprland ? "hyprland" : (niriProc.running ? "niri" : "none")

    property var workspaces: []

    function focus(ws) {
        if (onHyprland) Hyprland.dispatch("workspace " + ws.id)
        else Quickshell.execDetached(["niri", "msg", "action", "focus-workspace", String(ws.id)])
    }

    // ---------------- Hyprland ----------------
    readonly property var hyprWorkspaces: onHyprland ? Hyprland.workspaces.values : []

    function syncHyprland() {
        root.workspaces = hyprWorkspaces.map(w => ({
            id: w.id,
            name: w.name,
            focused: w.focused,
            urgent: w.urgent,
            output: w.monitor ? w.monitor.name : ""
        })).sort((a, b) => a.id - b.id)
    }

    onHyprWorkspacesChanged: if (onHyprland) syncHyprland()

    Connections {
        target: root.onHyprland ? Hyprland : null
        function onRawEvent(event) { root.syncHyprland() }
    }

    // ---------------- niri ----------------
    // The event stream tells us *when* something changed; the query gives the
    // authoritative list. Events are rare enough that re-querying is cheaper
    // than mirroring niri's whole event vocabulary.
    Process {
        id: niriProc
        running: !root.onHyprland
        command: ["niri", "msg", "--json", "event-stream"]
        stdout: SplitParser { onRead: refresh.restart() }
    }

    Timer {
        id: refresh
        interval: 40
        onTriggered: niriQuery.running = true
    }

    Process {
        id: niriQuery
        command: ["niri", "msg", "--json", "workspaces"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.workspaces = JSON.parse(text)
                        .map(w => ({
                            id: w.id,
                            name: w.name ? w.name : String(w.idx),
                            focused: w.is_focused,
                            urgent: w.is_urgent,
                            output: w.output ? w.output : ""
                        }))
                        .sort((a, b) => a.id - b.id)
                } catch (e) {
                    console.warn("Compositor: bad niri workspace payload — " + e)
                }
            }
        }
    }

    Component.onCompleted: if (onHyprland) syncHyprland()
}
