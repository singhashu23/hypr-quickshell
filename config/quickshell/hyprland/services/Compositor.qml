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

    // ---------------- open windows ----------------
    // Shape: { id, title, appId, workspace }. `id` is whatever the compositor
    // wants back in order to focus it — an address on Hyprland, a numeric id on
    // niri — so callers never need to know which one they are on.
    //
    // Queried on demand rather than mirrored: the list is only ever read while
    // the launcher is open, and it goes stale the moment it is used.
    property var windows: []

    function refreshWindows() {
        if (onHyprland) hyprWindows.running = true
        else niriWindows.running = true
    }

    function focusWindow(w) {
        if (!w) return
        if (onHyprland) Hyprland.dispatch("focuswindow address:" + w.id)
        else Quickshell.execDetached(["niri", "msg", "action", "focus-window", String(w.id)])
    }

    Process {
        id: hyprWindows
        command: ["hyprctl", "-j", "clients"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.windows = JSON.parse(text)
                        .filter(c => c.mapped && c.title)
                        .map(c => ({
                            id: c.address,
                            title: c.title,
                            appId: c.class ? c.class : "",
                            workspace: c.workspace && c.workspace.name ? c.workspace.name : ""
                        }))
                } catch (e) {
                    console.warn("Compositor: bad hyprctl clients payload — " + e)
                    root.windows = []
                }
            }
        }
    }

    Process {
        id: niriWindows
        command: ["niri", "msg", "--json", "windows"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.windows = JSON.parse(text).map(w => ({
                        id: w.id,
                        title: w.title ? w.title : "",
                        appId: w.app_id ? w.app_id : "",
                        workspace: w.workspace_id ? String(w.workspace_id) : ""
                    }))
                } catch (e) {
                    console.warn("Compositor: bad niri window payload — " + e)
                    root.windows = []
                }
            }
        }
    }

    Component.onCompleted: if (onHyprland) syncHyprland()
}
