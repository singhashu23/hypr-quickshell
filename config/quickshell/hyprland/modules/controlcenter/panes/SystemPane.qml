import QtQuick
import Quickshell
import Quickshell.Io
import qs
import qs.modules.controlcenter

Column {
    id: root
    spacing: Theme.gap

    // Sampled here rather than in a service on purpose: the pane only exists
    // while its tab is open, so nothing reads /proc when nobody is looking.
    property string distro: ""
    property string kernel: ""
    property string host: ""
    property string cpuModel: ""
    property string disk: ""

    property real cpuPct: 0
    property real memUsed: 0
    property real memTotal: 0
    property int uptime: 0
    property real rxRate: 0
    property real txRate: 0

    property real lastTotal: 0
    property real lastIdle: 0
    property real lastRx: 0
    property real lastTx: 0
    property real lastAt: 0

    function human(kb) {
        const gb = kb / 1048576
        return gb >= 1 ? gb.toFixed(1) + " GiB" : Math.round(kb / 1024) + " MiB"
    }
    function rate(bps) {
        return bps > 1048576 ? (bps / 1048576).toFixed(1) + " MB/s"
             : bps > 1024    ? (bps / 1024).toFixed(0) + " KB/s"
             : Math.max(0, Math.round(bps)) + " B/s"
    }
    function dur(s) {
        const d = Math.floor(s / 86400), h = Math.floor((s % 86400) / 3600), m = Math.floor((s % 3600) / 60)
        return (d > 0 ? d + "d " : "") + (h > 0 ? h + "h " : "") + m + "m"
    }

    Process {
        id: statics
        running: true
        command: ["sh", "-c",
            ". /etc/os-release 2>/dev/null; echo \"distro ${PRETTY_NAME:-Linux}\"; " +
            "echo \"kernel $(uname -r)\"; echo \"host $(uname -n)\"; " +
            "echo \"cpu $(awk -F: '/model name/{print $2; exit}' /proc/cpuinfo | sed 's/^ *//')\"; " +
            "echo \"disk $(df -h / | awk 'NR==2{print $3\" of \"$2\" (\"$5\")\"}')\""]
        stdout: StdioCollector {
            onStreamFinished: {
                for (const line of text.trim().split("\n")) {
                    const i = line.indexOf(" ")
                    if (i < 0) continue
                    const k = line.slice(0, i), v = line.slice(i + 1)
                    if (k === "distro") root.distro = v
                    else if (k === "kernel") root.kernel = v
                    else if (k === "host") root.host = v
                    else if (k === "cpu") root.cpuModel = v
                    else if (k === "disk") root.disk = v
                }
            }
        }
    }

    Process {
        id: sample
        running: true
        command: ["sh", "-c",
            "awk '/^cpu /{t=0; for(i=2;i<=NF;i++) t+=$i; print \"cpu\", t, $5+$6}' /proc/stat; " +
            "awk '/^MemTotal/{mt=$2} /^MemAvailable/{ma=$2} END{print \"mem\", mt, ma}' /proc/meminfo; " +
            "awk '{print \"up\", int($1)}' /proc/uptime; " +
            "awk 'NR>2 && $1 !~ /^lo:/ {rx+=$2; tx+=$10} END{print \"net\", rx+0, tx+0}' /proc/net/dev"]
        stdout: StdioCollector {
            onStreamFinished: {
                const now = Date.now() / 1000
                let total = 0, idle = 0, rx = 0, tx = 0
                for (const line of text.trim().split("\n")) {
                    const p = line.split(/\s+/)
                    if (p[0] === "cpu") { total = parseFloat(p[1]); idle = parseFloat(p[2]) }
                    else if (p[0] === "mem") {
                        root.memTotal = parseFloat(p[1])
                        root.memUsed = parseFloat(p[1]) - parseFloat(p[2])
                    }
                    else if (p[0] === "up") root.uptime = parseInt(p[1])
                    else if (p[0] === "net") { rx = parseFloat(p[1]); tx = parseFloat(p[2]) }
                }
                if (root.lastTotal > 0) {
                    const dt = total - root.lastTotal, di = idle - root.lastIdle
                    if (dt > 0) root.cpuPct = Math.max(0, Math.min(100, (dt - di) / dt * 100))
                    const secs = Math.max(0.1, now - root.lastAt)
                    root.rxRate = Math.max(0, (rx - root.lastRx) / secs)
                    root.txRate = Math.max(0, (tx - root.lastTx) / secs)
                }
                root.lastTotal = total; root.lastIdle = idle
                root.lastRx = rx; root.lastTx = tx; root.lastAt = now
            }
        }
    }

    Timer { interval: 2000; running: true; repeat: true; onTriggered: sample.running = true }

    CcSection {
        title: "Machine"

        CcRow { icon: "󰌽"; title: root.distro; subtitle: "Kernel " + root.kernel; interactive: false }
        CcRow { icon: "󰟀"; title: root.host;   subtitle: root.cpuModel;           interactive: false }
        CcRow { icon: "󰅐"; title: "Uptime";    subtitle: root.dur(root.uptime);   interactive: false }
        CcRow { icon: "󰋊"; title: "Disk";      subtitle: root.disk;               interactive: false }
    }

    CcSection {
        title: "Load"

        CcMeter {
            icon: "󰻠"
            label: "CPU"
            value: root.cpuPct / 100
            readout: Math.round(root.cpuPct) + "%"
            accent: root.cpuPct > 85 ? Theme.red : Theme.accent
        }

        CcMeter {
            icon: "󰍛"
            label: "Memory · " + root.human(root.memUsed) + " of " + root.human(root.memTotal)
            value: root.memTotal > 0 ? root.memUsed / root.memTotal : 0
            readout: root.memTotal > 0
                   ? Math.round(root.memUsed / root.memTotal * 100) + "%" : "—"
            accent: Theme.mauve
        }
    }

    CcSection {
        title: "Network"

        CcRow { icon: "󰇚"; title: "Down"; subtitle: root.rate(root.rxRate); interactive: false }
        CcRow { icon: "󰕒"; title: "Up";   subtitle: root.rate(root.txRate); interactive: false }
    }
}
