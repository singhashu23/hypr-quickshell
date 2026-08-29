import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import Quickshell.Services.Pam
import qs
import qs.services

// Session lock, on the compositor's own ext-session-lock protocol.
//
// The protocol is deliberately unforgiving: once locked, the session stays
// locked until *this process* unlocks it, and if the process dies the
// compositor keeps the screen blanked rather than letting anyone in. That is
// the security guarantee, and it means every failure path here has to end
// somewhere the user can still type — never in a disabled field. So PAM errors
// re-arm the prompt rather than latching, and the field is only ever disabled
// while a check is actually in flight.
Scope {
    id: root

    property string password: ""
    property bool busy: false
    property string status: ""
    property bool statusIsError: false
    property int attempts: 0

    readonly property bool locked: lock.locked

    function lock_() {
        if (lock.locked) return
        password = ""
        status = ""
        statusIsError = false
        attempts = 0
        lock.locked = true
    }

    function submit() {
        if (busy || password === "") return
        busy = true
        status = "Checking…"
        statusIsError = false
        if (!pam.start()) {
            // never leave the prompt dead: say so and let them try again
            busy = false
            status = "Could not start authentication"
            statusIsError = true
        }
    }

    function keyed(event) {
        if (busy) return
        switch (event.key) {
        case Qt.Key_Return:
        case Qt.Key_Enter:
            submit(); break
        case Qt.Key_Backspace:
            root.password = event.modifiers & Qt.ControlModifier
                          ? "" : root.password.slice(0, -1)
            break
        case Qt.Key_Escape:
            root.password = ""; break
        case Qt.Key_U:
            if (event.modifiers & Qt.ControlModifier) { root.password = ""; break }
            // fall through
        default:
            if (event.text && event.text.length === 1 && event.text >= " ")
                root.password += event.text
        }
        event.accepted = true
    }

    IpcHandler {
        target: "lock"
        function lock(): void { root.lock_() }
        function isLocked(): bool { return lock.locked }
        // A deliberate escape hatch. It does not weaken the lock: it protects
        // against someone at the keyboard, who cannot reach a shell to call
        // this without unlocking first. Anything already running as this user
        // is inside the fence regardless.
        function unlock(): void { lock.locked = false }
    }

    PamContext {
        id: pam
        // swaylock's config is `auth include login` — the auth stack on its
        // own, which is exactly what a locker needs, and it is already present
        // and proven on this machine.
        config: "swaylock"

        onPamMessage: {
            if (responseRequired) respond(root.password)
            else if (message !== "") {
                root.status = message
                root.statusIsError = messageIsError
            }
        }

        onCompleted: result => {
            root.busy = false
            if (result === PamResult.Success) {
                root.password = ""
                root.status = ""
                lock.locked = false
                return
            }
            root.password = ""
            root.attempts += 1
            root.statusIsError = true
            root.status = result === PamResult.MaxTries ? "Too many attempts"
                        : result === PamResult.Error    ? "Authentication error"
                        : "Wrong password"
            shakeAll.restart()
        }

        onError: err => {
            root.busy = false
            root.password = ""
            root.statusIsError = true
            root.status = "Authentication unavailable (" + err + ")"
        }
    }

    // one timer, so every surface shakes together
    Timer { id: shakeAll; interval: 1; repeat: false }

    WlSessionLock {
        id: lock

        surface: WlSessionLockSurface {
            id: surface
            color: Theme.base

            // ---------- the wallpaper, dimmed ----------
            Image {
                id: shot
                anchors.fill: parent
                source: Pywal.wallpaper !== "" ? "file://" + Pywal.wallpaper : ""
                fillMode: Image.PreserveAspectCrop
                sourceSize.width: Math.round(surface.width * Math.max(1, Screen.devicePixelRatio))
                asynchronous: true
                smooth: true
                mipmap: true
                visible: false
            }

            MultiEffect {
                anchors.fill: parent
                source: shot
                blurEnabled: true
                blur: 1.0
                blurMax: 48
                brightness: -0.45
                saturation: -0.2
                visible: shot.status === Image.Ready
            }

            // a ground under it, so a missing wallpaper is black rather than bare
            Rectangle {
                anchors.fill: parent
                color: Theme.base
                z: -1
            }

            // ---------- keyboard ----------
            Item {
                anchors.fill: parent
                focus: true
                Keys.onPressed: event => root.keyed(event)
                Component.onCompleted: forceActiveFocus()
                onVisibleChanged: if (visible) forceActiveFocus()
            }

            // ---------- the time ----------
            Column {
                id: clockCol
                anchors.horizontalCenter: parent.horizontalCenter
                y: parent.height * 0.24
                spacing: 4

                SystemClock { id: clock; precision: SystemClock.Minutes }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Qt.formatDateTime(clock.date, "HH:mm")
                    color: Theme.text
                    font.family: Theme.uiFont
                    font.pixelSize: 132
                    font.weight: Font.Light
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Qt.formatDateTime(clock.date, "dddd, d MMMM")
                    color: Theme.subtext
                    font.family: Theme.uiFont
                    font.pixelSize: Theme.fontSizeLarge
                }
            }

            // ---------- the prompt ----------
            Item {
                id: prompt
                anchors.horizontalCenter: parent.horizontalCenter
                y: clockCol.y + clockCol.height + 64
                width: 420
                height: field.height + 28

                // shake on a rejected password: the one piece of feedback that
                // needs no reading
                property real shake: 0
                x: shake
                Connections {
                    target: shakeAll
                    function onTriggered() { shakeAnim.restart() }
                }
                SequentialAnimation {
                    id: shakeAnim
                    loops: 2
                    NumberAnimation { target: prompt; property: "shake"; to:  9; duration: 45 }
                    NumberAnimation { target: prompt; property: "shake"; to: -9; duration: 45 }
                    NumberAnimation { target: prompt; property: "shake"; to:  0; duration: 45 }
                }

                Rectangle {
                    id: field
                    width: parent.width
                    height: 56
                    radius: Theme.radius
                    color: Theme.island
                    border.width: Theme.borderWidth
                    border.color: root.statusIsError ? Theme.red
                                : root.password !== "" ? Theme.selectionBorder : Theme.border

                    Behavior on border.color { ColorAnimation { duration: Theme.animFast } }

                    Text {
                        anchors { left: parent.left; leftMargin: Theme.padding + 4
                                  verticalCenter: parent.verticalCenter }
                        text: root.busy ? "󰔟" : "󰌾"
                        color: root.statusIsError ? Theme.red : Theme.accent
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeLarge
                    }

                    // dots rather than a TextInput: the field lives on every
                    // screen but the password is one string, and a TextInput
                    // per surface would fight over which of them owns it
                    Row {
                        id: dots
                        anchors.centerIn: parent
                        spacing: 9
                        visible: root.password.length > 0

                        Repeater {
                            model: Math.min(root.password.length, 24)
                            delegate: Rectangle {
                                width: 9; height: 9; radius: 4.5
                                color: Theme.text
                                opacity: 0.9
                            }
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        visible: root.password.length === 0
                        text: root.busy ? "" : "Password"
                        color: Theme.overlay
                        font.family: Theme.uiFont
                        font.pixelSize: Theme.fontSize
                    }
                }

                Text {
                    anchors { top: field.bottom; topMargin: 10
                              horizontalCenter: parent.horizontalCenter }
                    text: root.status
                    color: root.statusIsError ? Theme.red : Theme.subtext
                    font.family: Theme.uiFont
                    font.pixelSize: Theme.fontSize
                }
            }

            // ---------- who is logged in ----------
            Text {
                anchors { horizontalCenter: parent.horizontalCenter
                          bottom: parent.bottom; bottomMargin: 48 }
                text: Quickshell.env("USER") ? Quickshell.env("USER") : ""
                color: Theme.overlay
                font.family: Theme.uiFont
                font.pixelSize: Theme.fontSize
            }
        }
    }
}
