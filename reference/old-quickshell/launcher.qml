import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Effects
import QtQml.Models
import Quickshell
import Quickshell.Wayland
import Quickshell.Io

ShellRoot {
    id: root

    Timer {
        id: exitTimer
        interval: 150
        onTriggered: Qt.quit()
    }

    function launchApp(cmd) {
        execProcess.run(cmd);
        launcherWindow.visible = false;
        exitTimer.start();
    }

    // --- PYWAL ENGINE ---
    QtObject {
        id: pywal
        property color bg: "#fdf6e3"
        property color fg: "#4d4d4c"
        property color surface: "#eee8d5"
        property color border: "#333333"
        property color accent: "#859900"
        property color selection: "#eee8d5"
    }

    Process {
        command: ["sh", "-c", "cat ~/.cache/wal/colors.json 2>/dev/null | tr -d '\n'"]
        running: true
        stdout: SplitParser { onRead: (line) => {
            try {
                let wal = JSON.parse(line);
                pywal.bg = wal.special.background;
                pywal.fg = wal.special.foreground;
                pywal.surface = Qt.lighter(wal.special.background, 1.1);
                pywal.border = wal.colors.color8;
                pywal.accent = wal.colors.color2;
                pywal.selection = wal.colors.color1;
            } catch(e) {}
        }}
    }

    // --- APP SCANNER ---
    ListModel { id: appModel }
    ListModel { id: filteredModel }

    Process {
        id: appScanner
        // FIX: De-duplicate using the filename `apps[f] = ...` so "Files" doesn't overwrite another "Files"
        command: ["python3", "-c", "import os, json; apps = {}; paths = ['/usr/share/applications', os.path.expanduser('~/.local/share/applications')];\nfor path in paths:\n    if not os.path.exists(path): continue\n    for f in os.listdir(path):\n        if f.endswith('.desktop'):\n            try:\n                with open(os.path.join(path, f), 'r', errors='ignore') as d:\n                    lines = d.readlines(); name = next((l[5:].strip() for l in lines if l.startswith('Name=')), f);\n                    exec_cmd = next((l[5:].strip() for l in lines if l.startswith('Exec=')), '').split(' %')[0];\n                    comment = next((l[8:].strip() for l in lines if l.startswith('Comment=')), ''); icon = next((l[5:].strip() for l in lines if l.startswith('Icon=')), '');\n                    if exec_cmd and not any('NoDisplay=true' in l for l in lines): apps[f] = {'name': name, 'description': comment, 'icon': icon, 'exec': exec_cmd}\n            except: pass\nprint(json.dumps(sorted(apps.values(), key=lambda x: x['name'].lower())))"]
        running: true
        stdout: SplitParser { onRead: (line) => {
            try {
                let data = JSON.parse(line);
                appModel.clear();
                filteredModel.clear();
                for (let app of data) {
                    appModel.append(app);
                    filteredModel.append(app);
                }
            } catch(e) {}
        }}
    }

    PanelWindow {
        id: launcherWindow
        screen: Quickshell.focusedScreen

        WlrLayershell.layer: WlrLayershell.Overlay
        WlrLayershell.namespace: "quickshell-launcher"
        WlrLayershell.keyboardFocus: WlrLayershell.OnDemand

        anchors { top: true; bottom: true; left: true; right: true }
        color: "transparent"

        MouseArea {
            anchors.fill: parent
            onClicked: Qt.quit()
        }

        Rectangle {
            anchors.centerIn: parent
            width: 420; height: 620
            color: pywal.bg; radius: 16; border.color: pywal.border; border.width: 2; clip: true

            MouseArea {
                anchors.fill: parent
            }

            ColumnLayout {
                anchors.fill: parent; spacing: 0

                // --- HERO IMAGE SECTION ---
                Item {
                    Layout.fillWidth: true;
                    Layout.preferredHeight: 180;
                    Layout.margins: 12;

                    Image {
                        id: heroImg
                        anchors.fill: parent
                        source: "file://" + Quickshell.env("HOME") + "/Pictures/current.jpg"
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        visible: false
                    }

                    Rectangle {
                        id: maskShape
                        anchors.fill: parent
                        radius: 16
                        color: "black"
                        visible: false
                        layer.enabled: true
                    }

                    MultiEffect {
                        anchors.fill: parent
                        source: heroImg
                        maskEnabled: true
                        maskSource: maskShape
                    }

                    Rectangle {
                        anchors { bottom: parent.bottom; left: parent.left; right: parent.right; margins: 15 }
                        height: 44; color: "#cc000000"; radius: 10; border.color: pywal.accent; border.width: 1
                        RowLayout {
                            anchors.fill: parent; anchors.margins: 12
                            Text { text: ""; color: "white"; font.pixelSize: 16 }
                            TextInput {
                                id: searchInput; Layout.fillWidth: true; color: "white"
                                font.pixelSize: 16; focus: true; verticalAlignment: TextInput.AlignVCenter
                                horizontalAlignment: TextInput.AlignLeft

                                onTextChanged: {
                                    filteredModel.clear();
                                    let query = text.toLowerCase();
                                    for (let i = 0; i < appModel.count; i++) {
                                        let item = appModel.get(i);
                                        // FIX: Added `item.exec` to the search parameters
                                        if (item.name.toLowerCase().includes(query) ||
                                            item.description.toLowerCase().includes(query) ||
                                            item.exec.toLowerCase().includes(query)) {
                                            filteredModel.append({
                                                "name": item.name, "description": item.description,
                                                "icon": item.icon, "exec": item.exec
                                            });
                                        }
                                    }
                                    appListView.currentIndex = 0;
                                }

                                Keys.onUpPressed: {
                                    if (appListView.currentIndex > 0) appListView.currentIndex--;
                                    else if (appListView.count > 0) appListView.currentIndex = appListView.count - 1;
                                    appListView.positionViewAtIndex(appListView.currentIndex, ListView.Contain);
                                }
                                Keys.onDownPressed: {
                                    if (appListView.currentIndex < appListView.count - 1) appListView.currentIndex++;
                                    else if (appListView.count > 0) appListView.currentIndex = 0;
                                    appListView.positionViewAtIndex(appListView.currentIndex, ListView.Contain);
                                }
                                Keys.onEscapePressed: Qt.quit()
                                Keys.onReturnPressed: {
                                    if (filteredModel.count > 0 && appListView.currentIndex >= 0) {
                                        root.launchApp(filteredModel.get(appListView.currentIndex).exec)
                                    }
                                }
                            }
                        }
                    }
                }

                // Application List
                ListView {
                    id: appListView
                    Layout.fillWidth: true; Layout.fillHeight: true; Layout.margins: 12
                    spacing: 4; clip: true
                    model: filteredModel
                    currentIndex: 0

                    delegate: Rectangle {
                        width: appListView.width; height: 75
                        property bool isSelected: appListView.currentIndex === index
                        color: (isSelected || mouseArea.containsMouse) ? pywal.selection : "transparent"
                        radius: 8
                        RowLayout {
                            anchors.fill: parent; anchors.margins: 15; spacing: 15
                            Image {
                                Layout.preferredWidth: 42; Layout.preferredHeight: 42
                                sourceSize.width: 42; sourceSize.height: 42
                                source: model.icon ? "image://icon/" + model.icon : ""
                                fillMode: Image.PreserveAspectFit; clip: true
                            }
                            ColumnLayout {
                                spacing: 2; Layout.fillWidth: true
                                Text {
                                    text: model.name; font.bold: true; color: pywal.fg
                                    horizontalAlignment: Text.AlignLeft; Layout.fillWidth: true
                                }
                                Text {
                                    text: model.description; font.pixelSize: 11; color: pywal.fg; opacity: 0.7
                                    horizontalAlignment: Text.AlignLeft; Layout.fillWidth: true; elide: Text.ElideRight
                                }
                            }
                        }
                        MouseArea {
                            id: mouseArea; anchors.fill: parent; hoverEnabled: true
                            onPositionChanged: { if (appListView.currentIndex !== index) appListView.currentIndex = index; }
                            onClicked: root.launchApp(model.exec)
                        }
                    }
                }
            }
        }
    }

    Process {
        id: execProcess
        function run(cmd) {
            command = ["sh", "-c", "nohup " + cmd + " >/dev/null 2>&1 &"];
            running = true;
        }
    }
}
