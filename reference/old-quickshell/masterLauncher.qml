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

    property int activeTab: 0
    property string calcResult: ""

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

    function focusWindow(winId) {
        execProcess.run("niri msg action focus-window --id " + winId);
        launcherWindow.visible = false;
        exitTimer.start();
    }

    function calculate(expression) {
        if (expression.trim() === "") { root.calcResult = ""; return; }
        let sanitized = expression.replace(/[^0-9+\-*/(). ]/g, '');
        if (sanitized === "") { root.calcResult = ""; return; }

        try {
            let res = Function("return " + sanitized)();
            if (res === Infinity || res === -Infinity) root.calcResult = "∞";
            else if (isNaN(res)) root.calcResult = "Error";
            else root.calcResult = parseFloat(res.toFixed(6)).toString();
        } catch(e) {
            root.calcResult = "";
        }
    }

    function applyFilter(textQuery) {
        let query = textQuery.toLowerCase();

        filteredModel.clear();
        for (let i = 0; i < appModel.count; i++) {
            let item = appModel.get(i);
            if (item.name.toLowerCase().includes(query) ||
                item.description.toLowerCase().includes(query) ||
                item.exec.toLowerCase().includes(query)) {
                filteredModel.append({ "name": item.name, "description": item.description, "icon": item.icon, "exec": item.exec });
            }
        }

        filteredWindowModel.clear();
        for (let i = 0; i < windowModel.count; i++) {
            let item = windowModel.get(i);
            let wTitle = item.title ? item.title.toLowerCase() : "";
            let wAppId = item.app_id ? item.app_id.toLowerCase() : "";

            if (wTitle.includes(query) || wAppId.includes(query)) {
                filteredWindowModel.append({ "id": item.id, "title": item.title, "app_id": item.app_id, "icon": item.icon });
            }
        }

        appListView.currentIndex = 0;
        windowListView.currentIndex = 0;
    }

    onActiveTabChanged: {
        if (activeTab === 1) windowScanner.running = true;
    }

    // --- PYWAL ENGINE ---
    QtObject {
        id: pywal
        property color bg: "#1e1e2e"
        property color fg: "#cdd6f4"
        property color surface: "#313244"
        property color border: "#45475a"
        property color accent: "#89b4fa"
        // FIX: Dropped opacity to 15% for an ultra-sleek, subtle tint
        property color selection: Qt.alpha(accent, 0.15)
    }

    Process {
        command: ["sh", "-c", "cat ~/.cache/wal/colors.json 2>/dev/null | tr -d '\n'"]
        running: true
        stdout: SplitParser { onRead: (line) => {
            try {
                let wal = JSON.parse(line);
                pywal.bg = wal.special.background;
                pywal.fg = wal.special.foreground;
                pywal.surface = Qt.lighter(wal.special.background, 1.5);
                pywal.border = wal.colors.color8;
                pywal.accent = wal.colors.color4;
            } catch(e) {}
        }}
    }

    // --- SCANNERS ---
    ListModel { id: appModel }
    ListModel { id: filteredModel }

    Process {
        id: appScanner
        command: ["python3", "-c", "import os, json; apps = {}; paths = ['/usr/share/applications', os.path.expanduser('~/.local/share/applications')];\nfor path in paths:\n    if not os.path.exists(path): continue\n    for f in os.listdir(path):\n        if f.endswith('.desktop'):\n            try:\n                with open(os.path.join(path, f), 'r', errors='ignore') as d:\n                    lines = d.readlines(); name = next((l[5:].strip() for l in lines if l.startswith('Name=')), f);\n                    exec_cmd = next((l[5:].strip() for l in lines if l.startswith('Exec=')), '').split(' %')[0];\n                    comment = next((l[8:].strip() for l in lines if l.startswith('Comment=')), ''); icon = next((l[5:].strip() for l in lines if l.startswith('Icon=')), '');\n                    if exec_cmd and not any('NoDisplay=true' in l for l in lines): apps[f] = {'name': name, 'description': comment, 'icon': icon, 'exec': exec_cmd}\n            except: pass\nprint(json.dumps(sorted(apps.values(), key=lambda x: x['name'].lower())))"]
        running: true
        stdout: SplitParser { onRead: (line) => {
            try {
                let data = JSON.parse(line);
                appModel.clear();
                for (let app of data) appModel.append(app);
                root.applyFilter(searchInput.text);
            } catch(e) {}
        }}
    }

    ListModel { id: windowModel }
    ListModel { id: filteredWindowModel }

    Process {
        id: windowScanner
        running: true
        command: ["python3", "-c", "import subprocess, json\ntry:\n out=subprocess.check_output(['niri', 'msg', '-j', 'windows']).decode()\n print(json.dumps(json.loads(out)))\nexcept:\n print('[]')"]
        stdout: SplitParser { onRead: (line) => {
            try {
                let data = JSON.parse(line);
                windowModel.clear();
                for (let win of data) {
                    let appIcon = win.app_id ? win.app_id.toLowerCase() : "preferences-system-windows";
                    windowModel.append({ "id": win.id, "title": win.title || win.app_id || "Unknown Window", "app_id": win.app_id || "", "icon": appIcon });
                }
                root.applyFilter(searchInput.text);
            } catch(e) {}
        }}
    }

    // --- UI LAYOUT ---
    PanelWindow {
        id: launcherWindow
        screen: Quickshell.focusedScreen

        WlrLayershell.layer: WlrLayershell.Overlay
        WlrLayershell.namespace: "quickshell-launcher"
        WlrLayershell.keyboardFocus: WlrLayershell.OnDemand

        anchors { top: true; bottom: true; left: true; right: true }
        color: "transparent"

        MouseArea { anchors.fill: parent; onClicked: Qt.quit() }

        Rectangle {
            anchors.centerIn: parent
            width: 420; height: 620
            color: pywal.bg; radius: 16; border.color: pywal.border; border.width: 2; clip: true

            MouseArea { anchors.fill: parent }

            ColumnLayout {
                anchors.fill: parent; spacing: 0

                Item {
                    Layout.fillWidth: true; Layout.preferredHeight: 180; Layout.margins: 12;

                    Image {
                        id: heroImg
                        anchors.fill: parent; source: "file://" + Quickshell.env("HOME") + "/Pictures/current.jpg"
                        fillMode: Image.PreserveAspectCrop; asynchronous: true; visible: false
                    }
                    Rectangle {
                        id: maskShape; anchors.fill: parent; radius: 16; color: "black"; visible: false; layer.enabled: true
                    }
                    MultiEffect { anchors.fill: parent; source: heroImg; maskEnabled: true; maskSource: maskShape }

                    Rectangle {
                        anchors { bottom: parent.bottom; left: parent.left; right: parent.right; margins: 15 }
                        height: 44; color: "#cc000000"; radius: 10; border.color: pywal.accent; border.width: 1
                        RowLayout {
                            anchors.fill: parent; anchors.margins: 12
                            Text { text: root.activeTab === 2 ? "" : ""; color: "white"; font.pixelSize: 16 }
                            TextInput {
                                id: searchInput; Layout.fillWidth: true; color: "white"
                                font.pixelSize: 16; focus: true; verticalAlignment: TextInput.AlignVCenter

                                onTextChanged: {
                                    root.applyFilter(text);
                                    root.calculate(text);
                                }

                                Keys.onUpPressed: {
                                    let list = root.activeTab === 0 ? appListView : windowListView;
                                    if (list.currentIndex > 0) list.currentIndex--;
                                    else if (list.count > 0) list.currentIndex = list.count - 1;
                                    list.positionViewAtIndex(list.currentIndex, ListView.Contain);
                                }
                                Keys.onDownPressed: {
                                    let list = root.activeTab === 0 ? appListView : windowListView;
                                    if (list.currentIndex < list.count - 1) list.currentIndex++;
                                    else if (list.count > 0) list.currentIndex = 0;
                                    list.positionViewAtIndex(list.currentIndex, ListView.Contain);
                                }

                                Keys.onLeftPressed: (event) => {
                                    if (text === "") { root.activeTab = (root.activeTab + 2) % 3; event.accepted = true; }
                                }
                                Keys.onRightPressed: (event) => {
                                    if (text === "") { root.activeTab = (root.activeTab + 1) % 3; event.accepted = true; }
                                }
                                Keys.onTabPressed: { root.activeTab = (root.activeTab + 1) % 3; }

                                Keys.onEscapePressed: Qt.quit()
                                Keys.onReturnPressed: {
                                    if (root.activeTab === 0) {
                                        if (filteredModel.count > 0 && appListView.currentIndex >= 0) root.launchApp(filteredModel.get(appListView.currentIndex).exec)
                                    } else if (root.activeTab === 1) {
                                        if (filteredWindowModel.count > 0 && windowListView.currentIndex >= 0) root.focusWindow(filteredWindowModel.get(windowListView.currentIndex).id)
                                    } else if (root.activeTab === 2) {
                                        if (root.calcResult !== "") text = root.calcResult;
                                    }
                                }
                            }
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true; Layout.margins: 12; Layout.topMargin: 0; spacing: 8

                    Repeater {
                        model: ["", "", ""]
                        delegate: Rectangle {
                            Layout.fillWidth: true; height: 36; radius: 8
                            color: root.activeTab === index ? pywal.accent : "#00000000"
                            border.color: root.activeTab === index ? "transparent" : pywal.surface; border.width: 2
                            Text {
                                anchors.centerIn: parent; text: modelData
                                font.pixelSize: 16
                                color: root.activeTab === index ? pywal.bg : pywal.fg
                            }
                            MouseArea { anchors.fill: parent; onClicked: root.activeTab = index }
                        }
                    }
                }

                ListView {
                    id: appListView
                    visible: root.activeTab === 0
                    Layout.fillWidth: true; Layout.fillHeight: true; Layout.margins: 12; Layout.topMargin: 0
                    spacing: 4; clip: true; model: filteredModel; currentIndex: 0

                    delegate: Rectangle {
                        width: appListView.width; height: 75
                        property bool isSelected: appListView.currentIndex === index

                        color: (isSelected || mouseArea.containsMouse) ? pywal.selection : "#00000000"
                        radius: 10

                        RowLayout {
                            anchors.fill: parent; anchors.margins: 15; spacing: 15
                            Image { Layout.preferredWidth: 42; Layout.preferredHeight: 42; sourceSize.width: 42; sourceSize.height: 42; source: model.icon ? "image://icon/" + model.icon : ""; fillMode: Image.PreserveAspectFit; clip: true }
                            ColumnLayout {
                                spacing: 2; Layout.fillWidth: true
                                Text { text: model.name; font.bold: true; color: pywal.fg; Layout.fillWidth: true }
                                Text { text: model.description; font.pixelSize: 11; color: pywal.fg; opacity: 0.7; Layout.fillWidth: true; elide: Text.ElideRight }
                            }
                        }
                        MouseArea {
                            id: mouseArea; anchors.fill: parent; hoverEnabled: true
                            onPositionChanged: { if (appListView.currentIndex !== index) appListView.currentIndex = index; }
                            onClicked: root.launchApp(model.exec)
                        }
                    }
                }

                ListView {
                    id: windowListView
                    visible: root.activeTab === 1
                    Layout.fillWidth: true; Layout.fillHeight: true; Layout.margins: 12; Layout.topMargin: 0
                    spacing: 4; clip: true; model: filteredWindowModel; currentIndex: 0

                    delegate: Rectangle {
                        width: windowListView.width; height: 75
                        property bool isSelected: windowListView.currentIndex === index

                        color: (isSelected || mouseArea2.containsMouse) ? pywal.selection : "#00000000"
                        radius: 10

                        RowLayout {
                            anchors.fill: parent; anchors.margins: 15; spacing: 15
                            Image { Layout.preferredWidth: 42; Layout.preferredHeight: 42; sourceSize.width: 42; sourceSize.height: 42; source: "image://icon/" + model.icon; fillMode: Image.PreserveAspectFit; clip: true }
                            ColumnLayout {
                                spacing: 2; Layout.fillWidth: true
                                Text { text: model.title; font.bold: true; color: pywal.fg; Layout.fillWidth: true; elide: Text.ElideRight }
                                Text { text: "App: " + model.app_id; font.pixelSize: 11; color: pywal.fg; opacity: 0.7; Layout.fillWidth: true; elide: Text.ElideRight }
                            }
                        }
                        MouseArea {
                            id: mouseArea2; anchors.fill: parent; hoverEnabled: true
                            onPositionChanged: { if (windowListView.currentIndex !== index) windowListView.currentIndex = index; }
                            onClicked: root.focusWindow(model.id)
                        }
                    }
                }

                Item {
                    visible: root.activeTab === 2
                    Layout.fillWidth: true; Layout.fillHeight: true; Layout.margins: 12; Layout.topMargin: 0

                    ColumnLayout {
                        anchors.fill: parent
                        spacing: 15

                        Text {
                            Layout.fillWidth: true; Layout.preferredHeight: 60
                            text: root.calcResult !== "" ? "= " + root.calcResult : ""
                            font.pixelSize: 42; font.bold: true
                            color: pywal.accent
                            horizontalAlignment: Text.AlignRight
                            verticalAlignment: Text.AlignVCenter
                            elide: Text.ElideLeft
                        }

                        GridLayout {
                            Layout.fillWidth: true; Layout.fillHeight: true
                            columns: 4; rowSpacing: 8; columnSpacing: 8

                            Repeater {
                                model: ["C", "(", ")", "/",
                                        "7", "8", "9", "*",
                                        "4", "5", "6", "-",
                                        "1", "2", "3", "+",
                                        "0", ".", "<-", "="]
                                delegate: CalcButton { label: modelData }
                            }
                        }
                    }
                }
            }
        }
    }

    component CalcButton: Rectangle {
        property string label: ""
        property bool isAccent: label === "=" || label === "C" || label === "<-" || label === "/" || label === "*" || label === "-" || label === "+"

        Layout.fillWidth: true; Layout.fillHeight: true
        radius: 10
        color: mouseAreaCalc.containsMouse ? pywal.selection : (isAccent ? Qt.darker(pywal.surface, 1.2) : "transparent")
        border.color: pywal.surface; border.width: 1

        Text {
            anchors.centerIn: parent; text: label
            font.pixelSize: 20; font.bold: true
            color: isAccent ? pywal.accent : pywal.fg
        }

        MouseArea {
            id: mouseAreaCalc; anchors.fill: parent; hoverEnabled: true
            onClicked: {
                searchInput.forceActiveFocus();
                if (label === "C") searchInput.text = "";
                else if (label === "<-") searchInput.text = searchInput.text.slice(0, -1);
                else if (label === "=") { if (root.calcResult !== "") searchInput.text = root.calcResult; }
                else searchInput.text += label;
            }
        }
    }

    Process {
        id: execProcess
        function run(cmd) { command = ["sh", "-c", "nohup " + cmd + " >/dev/null 2>&1 &"]; running = true; }
    }
}
