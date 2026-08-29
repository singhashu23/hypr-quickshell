import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import qs
import qs.services

// Unified launcher. At rest it shows the time; typing turns it into a result
// list. Same island, same corner, same motion as the bar — one surface.
PanelWindow {
    id: root

    property bool active: false
    property string query: ""
    property int index: 0

    // the wallpaper pywal last themed from; "" until its cache exists
    readonly property string wallpaper: Pywal.wallpaper
    readonly property bool hasWall: wallpaper !== ""

    readonly property var results: Apps.search(query)
    readonly property bool searching: query.trim() !== ""

    // simple arithmetic, shown above the results when the query looks like a sum
    readonly property string calc: {
        const q = query.trim()
        if (!/^[-+*/(). 0-9]+$/.test(q) || !/[-+*/]/.test(q)) return ""
        try {
            const v = Function("return (" + q + ")")()
            return (typeof v === "number" && isFinite(v)) ? String(v) : ""
        } catch (e) { return "" }
    }

    function open() {
        query = ""
        index = 0
        active = true
        input.forceActiveFocus()
    }
    function close() { active = false; query = "" }
    function toggle() { active ? close() : open() }

    function run() {
        if (results.length === 0) return
        Apps.launch(results[Math.min(index, results.length - 1)])
        close()
    }

    visible: active
    color: "transparent"
    anchors { top: true; bottom: true; left: true; right: true }

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: active ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    WlrLayershell.namespace: "qs-launcher"

    IpcHandler {
        target: "launcher"
        function toggle(): void { root.toggle() }
        function open(): void { root.open() }
        function close(): void { root.close() }
    }

    // click-away
    MouseArea {
        anchors.fill: parent
        onClicked: root.close()
    }

    Item {
        id: card
        anchors.horizontalCenter: parent.horizontalCenter
        y: parent.height * 0.18
        width: shell.width
        height: shell.height

        opacity: root.active ? 1 : 0
        scale: root.active ? 1 : 0.97
        Behavior on opacity { NumberAnimation { duration: Theme.animNormal; easing.type: Theme.easing } }
        Behavior on scale   { NumberAnimation { duration: Theme.animNormal; easing.type: Theme.easing } }

        // swallow clicks so click-away only fires outside the card
        MouseArea { anchors.fill: parent }

        Rectangle {
            id: shell
            readonly property int colWidth: 620

            // The wallpaper tile is a fixed size: it comes from the image's own
            // ratio and the caps below, never from what the card is showing.
            // Capping both axes keeps an ultrawide or portrait wallpaper from
            // running away along its long edge.
            readonly property int wallMargin:    12
            readonly property int wallMaxWidth:  846   // 1.8x
            readonly property int wallMaxHeight: 612   // 1.8x
            readonly property real wallAspect: wall.implicitHeight > 0
                                             ? wall.implicitWidth / wall.implicitHeight
                                             : 16 / 9
            readonly property real wallWidth:  root.hasWall ? Math.min(wallMaxWidth, wallMaxHeight * wallAspect) : 0
            readonly property real wallHeight: root.hasWall ? wallWidth / wallAspect : 0
            readonly property int paneWidth: root.hasWall ? Math.round(wallWidth + wallMargin * 2) : 0

            // Both axes are fixed. The card is the tile plus its margins, so a
            // growing result list scrolls inside a static body rather than
            // resizing the launcher under the cursor. Only a wallpaper of a
            // different shape moves these, which is what the Behaviors are for.
            width: paneWidth + colWidth
            height: root.hasWall ? Math.round(wallHeight + wallMargin * 2)
                                 : header.height + 150
            radius: Theme.radius + 4
            color: Theme.island
            border.width: Theme.borderWidth
            border.color: Theme.border
            clip: true

            Behavior on height { NumberAnimation { duration: Theme.animNormal; easing.type: Theme.easing } }
            Behavior on width  { NumberAnimation { duration: Theme.animNormal; easing.type: Theme.easing } }

            // ---------- left: the current wallpaper, entire ----------
            // Inset from the card on every side by the same margin, so it reads
            // as a tile resting on the island rather than a bleed off its edge.
Item {
                id: wallTile
                visible: root.hasWall
                x: shell.wallMargin
                y: shell.wallMargin
                width:  shell.wallWidth
                height: shell.wallHeight

                // ground under the picture while it decodes
                Rectangle {
                    anchors.fill: parent
                    radius: Theme.radius
                    color: Theme.surface0
                }

                Image {
                    id: wall
                    anchors.fill: parent
                    source: root.hasWall ? "file://" + root.wallpaper : ""
                    // the tile already carries the image's ratio, so fitting
                    // fills it exactly — whole picture, no crop, no bars
                    fillMode: Image.PreserveAspectFit
                    sourceSize.width: 1200
                    asynchronous: true
                    smooth: true
                    visible: false          // drawn through the mask below
                }

                // Qt's `clip` follows an item's bounding box, not its radius, so
                // a rounded Rectangle around an Image still shows square corners.
                // Masking is what actually rounds the picture.
                Item {
                    id: wallMask
                    anchors.fill: parent
                    layer.enabled: true
                    visible: false

                    Rectangle {
                        anchors.fill: parent
                        radius: Theme.radius
                        color: "black"
                    }
                }

                MultiEffect {
                    anchors.fill: parent
                    source: wall
                    maskEnabled: true
                    maskSource: wallMask
                }

                // hairline, so the tile still reads as an edge against a
                // wallpaper whose own borders happen to be dark
                Rectangle {
                    anchors.fill: parent
                    radius: Theme.radius
                    color: "transparent"
                    border.width: Theme.borderWidth
                    border.color: Theme.border
                }
            }

            // ---------- header: search ----------
            Item {
                id: header
                x: shell.paneWidth
                width: shell.colWidth
                height: 70

                Text {
                    id: prompt
                    anchors { left: parent.left; leftMargin: Theme.padding + 6; verticalCenter: parent.verticalCenter }
                    text: root.searching ? "󰍉" : "󰀻"
                    color: Theme.accent
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeLarge
                }

                TextInput {
                    id: input
                    anchors {
                        left: prompt.right; leftMargin: Theme.padding
                        right: parent.right; rightMargin: Theme.padding
                        verticalCenter: parent.verticalCenter
                    }
                    text: root.query
                    onTextChanged: { root.query = text; root.index = 0 }
                    color: Theme.text
                    font.family: Theme.uiFont
                    font.pixelSize: Theme.fontSizeLarge
                    selectByMouse: true
                    selectionColor: Theme.alpha(Theme.accent, 0.35)
                    clip: true

                    Text {
                        anchors.fill: parent
                        visible: input.text === ""
                        text: "Search applications…"
                        color: Theme.overlay
                        font: input.font
                        verticalAlignment: Text.AlignVCenter
                    }

                    Keys.onEscapePressed: root.close()
                    Keys.onReturnPressed: root.run()
                    Keys.onEnterPressed: root.run()
                    Keys.onDownPressed: root.index = Math.min(root.index + 1, root.results.length - 1)
                    Keys.onUpPressed:   root.index = Math.max(root.index - 1, 0)
                    Keys.onTabPressed:  root.index = (root.index + 1) % Math.max(1, root.results.length)
                }

                Rectangle {
                    anchors { left: parent.left; right: parent.right; bottom: parent.bottom
                              leftMargin: Theme.padding; rightMargin: Theme.padding }
                    height: 1
                    color: Theme.border
                    visible: body.height > 0
                }
            }

            // ---------- body: clock at rest, results while searching ----------
            Item {
                id: body
                anchors.top: header.bottom
                x: shell.paneWidth
                width: shell.colWidth
                // whatever the card has left under the search field — static,
                // so a long result list scrolls instead of growing the launcher
                height: shell.height - header.height

                // at rest
                Column {
                    anchors.centerIn: parent
                    visible: !root.searching
                    spacing: 2

                    SystemClock { id: clock; precision: SystemClock.Minutes }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: Qt.formatDateTime(clock.date, "HH:mm")
                        color: Theme.text
                        font.family: Theme.uiFont
                        font.pixelSize: 76
                        font.weight: Font.Light
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: Qt.formatDateTime(clock.date, "dddd, d MMMM")
                        color: Theme.overlay
                        font.family: Theme.uiFont
                        font.pixelSize: Theme.fontSize + 2
                    }
                }

                // calculator result
                Rectangle {
                    id: calcRow
                    visible: root.searching && root.calc !== ""
                    anchors { top: parent.top; left: parent.left; right: parent.right
                              margins: Theme.gap }
                    height: visible ? 44 : 0
                    radius: Theme.radiusSmall
                    color: Theme.surface0

                    Text {
                        anchors { left: parent.left; leftMargin: Theme.padding; verticalCenter: parent.verticalCenter }
                        text: "󰃬  " + root.query.trim() + "  =  " + root.calc
                        color: Theme.accent
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize
                    }
                }

                ListView {
                    id: list
                    visible: root.searching
                    anchors {
                        top: calcRow.visible ? calcRow.bottom : parent.top
                        left: parent.left; right: parent.right; bottom: parent.bottom
                        margins: Theme.gap
                    }
                    clip: true
                    model: root.results
                    currentIndex: root.index
                    highlightMoveDuration: Theme.animFast
                    boundsBehavior: Flickable.StopAtBounds

                    delegate: Rectangle {
                        required property var modelData
                        required property int index

                        width: list.width
                        height: 52
                        radius: Theme.radiusSmall
                        color: index === root.index ? Theme.surface1
                             : hover.hovered ? Theme.surface0 : "transparent"

                        Behavior on color { ColorAnimation { duration: Theme.animFast } }

                        HoverHandler { id: hover }
                        TapHandler {
                            onTapped: { root.index = index; root.run() }
                        }

                        Image {
                            id: icon
                            anchors { left: parent.left; leftMargin: Theme.padding; verticalCenter: parent.verticalCenter }
                            width: 30; height: 30
                            source: modelData.icon ? "file://" + modelData.icon : ""
                            sourceSize: Qt.size(64, 64)
                            fillMode: Image.PreserveAspectFit
                            visible: status === Image.Ready
                            asynchronous: true
                        }

                        // fallback glyph when the theme has no icon for it
                        Text {
                            anchors.centerIn: icon
                            visible: !icon.visible
                            text: "󰣆"
                            color: Theme.overlay
                            font.family: Theme.fontFamily
                            font.pixelSize: 20
                        }

                        Column {
                            anchors {
                                left: icon.right; leftMargin: Theme.padding
                                right: parent.right; rightMargin: Theme.padding
                                verticalCenter: parent.verticalCenter
                            }
                            spacing: 1

                            Text {
                                width: parent.width
                                text: modelData.name
                                color: Theme.text
                                elide: Text.ElideRight
                                font.family: Theme.uiFont
                                font.pixelSize: Theme.fontSize + 1
                            }
                            Text {
                                width: parent.width
                                visible: modelData.comment !== ""
                                text: modelData.comment
                                color: Theme.overlay
                                elide: Text.ElideRight
                                font.family: Theme.uiFont
                                font.pixelSize: Theme.fontSize - 1
                            }
                        }
                    }
                }

                Text {
                    anchors.centerIn: parent
                    visible: root.searching && root.results.length === 0 && root.calc === ""
                    text: "no matches"
                    color: Theme.overlay
                    font.family: Theme.uiFont
                    font.pixelSize: Theme.fontSize
                }
            }
        }
    }
}
