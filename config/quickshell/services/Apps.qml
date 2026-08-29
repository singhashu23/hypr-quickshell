pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Desktop-entry index for the launcher. scripts/apps.py does the parsing and
// resolves every icon to an absolute path using the live GTK icon theme.
Singleton {
    id: root

    property var apps: []
    property bool loading: true

    function reload() {
        loading = true
        scanner.running = true
    }

    // Ranked substring match. Name hits outrank keyword/comment hits, and a
    // prefix outranks a mid-string hit, so typing "fir" puts Firefox first.
    function search(query) {
        const q = query.trim().toLowerCase()
        if (q === "") return apps

        const scored = []
        for (const a of apps) {
            const name = a.name.toLowerCase()
            let score = -1

            if (name === q) score = 1000
            else if (name.startsWith(q)) score = 900 - name.length
            else if (name.indexOf(q) !== -1) score = 700 - name.length
            else if ((a.keywords || "").toLowerCase().indexOf(q) !== -1) score = 400
            else if ((a.comment || "").toLowerCase().indexOf(q) !== -1) score = 300
            else if ((a.exec || "").toLowerCase().indexOf(q) !== -1) score = 200

            if (score >= 0) scored.push({ app: a, score: score })
        }
        scored.sort((x, y) => y.score - x.score || x.app.name.localeCompare(y.app.name))
        return scored.map(s => s.app)
    }

    function launch(app) {
        if (!app) return
        if (app.terminal) Quickshell.execDetached(["sh", "-c", "kitty -e " + app.exec])
        else Quickshell.execDetached(["sh", "-c", app.exec])
    }

    Process {
        id: scanner
        running: true
        command: ["python3", Quickshell.shellDir + "/scripts/apps.py"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.apps = JSON.parse(text)
                } catch (e) {
                    console.warn("Apps: scanner produced no usable JSON — " + e)
                    root.apps = []
                }
                root.loading = false
            }
        }
    }
}
