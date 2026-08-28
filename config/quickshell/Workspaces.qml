import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

Rectangle {
    id: root

    // Properties injected dynamically by pywal in shell.qml
    property color accentColor: "#7aa2f7"
    property color baseColor: "#1a1b26"
    property color surfaceColor: "#24283b"

    implicitWidth: 36
    implicitHeight: wsColumn.implicitHeight + 20
    radius: 18
    color: root.surfaceColor

    anchors.horizontalCenter: parent.horizontalCenter

    property string monitorName: ""
    property string activeWsId: ""

    ListModel { id: wsModel }

    Process {
        id: wsCommandRunner
        function run(cmd) { command = cmd; running = true; }
    }

    Process {
        id: niriEvents
        command: ["sh", "-c", "niri msg --json event-stream"]
        running: true
        stdout: SplitParser {
            onRead: (line) => {
                try {
                    let ev = JSON.parse(line);
                    if (ev.WorkspaceActivated) {
                        root.activeWsId = ev.WorkspaceActivated.id.toString();
                    }
                    else if (ev.WorkspacesChanged) {
                        let wss = ev.WorkspacesChanged.workspaces;
                        wss.sort(function(a, b) { return a.idx - b.idx; });
                        wsModel.clear();
                        for (let i = 0; i < wss.length; i++) {
                            let w = wss[i];
                            if (root.monitorName === "" || w.output === root.monitorName) {
                                wsModel.append({ "wsId": w.id.toString(), "wsIdx": w.idx.toString() });
                                if (w.is_focused || w.is_active) {
                                    root.activeWsId = w.id.toString();
                                }
                            }
                        }
                    }
                } catch(e) {}
            }
        }
    }

    Column {
        id: wsColumn
        anchors.centerIn: parent
        spacing: 12

        Repeater {
            model: wsModel

            Rectangle {
                property string myId: model.wsId
                property bool isActive: myId === root.activeWsId

                implicitWidth: isActive ? 28 : 8
                implicitHeight: isActive ? 28 : 8
                radius: width / 2

                anchors.horizontalCenter: parent.horizontalCenter

                // FIX: Both active and inactive dots now use the Pywal accent color!
                color: root.accentColor

                Behavior on implicitHeight { NumberAnimation { duration: 250; easing.type: Easing.OutBack } }
                Behavior on implicitWidth { NumberAnimation { duration: 250; easing.type: Easing.OutBack } }
                Behavior on color { ColorAnimation { duration: 200 } }

                Text {
                    anchors.centerIn: parent
                    text: "󰮯"
                    font.pixelSize: 16
                    color: root.baseColor

                    opacity: isActive ? 1.0 : 0.0
                    Behavior on opacity { NumberAnimation { duration: 200 } }
                }

                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -12
                    onClicked: {
                        wsCommandRunner.run(["niri", "msg", "action", "focus-workspace", model.wsIdx]);
                    }
                }
            }
        }
    }
}
