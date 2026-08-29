pragma Singleton

import QtQuick
import Quickshell

// Notification history and Do Not Disturb.
//
// The server only keeps what is currently on screen, so history is recorded
// here as plain snapshots rather than references: a Notification is owned by
// the server and is gone once dismissed, and holding one past that point is a
// dangling read.
Singleton {
    id: root

    property bool dnd: false
    property var history: []
    readonly property int limit: 60

    function record(n, critical) {
        const entry = {
            appName: n.appName ? n.appName : "",
            summary: n.summary ? n.summary : "",
            body: n.body ? n.body : "",
            image: n.image ? n.image : "",
            appIcon: n.appIcon ? n.appIcon : "",
            critical: critical === true,
            at: new Date()
        }
        // reassign rather than push: a bare push does not notify bindings
        history = [entry].concat(history).slice(0, limit)
    }

    function clear() { history = [] }
}
