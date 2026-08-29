import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import qs
import qs.services

// Unified launcher. One island, three tabs: applications, the windows that are
// already open, and a calculator — the same three the niri launcher carries.
// Same corner, same motion as the bar.
PanelWindow {
    id: root

    property bool active: false
    property string query: ""
    property int index: 0

    // 0 apps · 1 open windows · 2 calculator
    property int tab: 0
    readonly property var tabs: [
        { glyph: "󰀻", name: "Apps",       hint: "Search applications…" },
        { glyph: "󰖯", name: "Windows",    hint: "Search open windows…" },
        { glyph: "󰃬", name: "Calculator", hint: "Type an expression…" }
    ]

    // the wallpaper pywal last themed from; "" until its cache exists
    readonly property string wallpaper: Pywal.wallpaper
    readonly property bool hasWall: wallpaper !== ""

    readonly property bool searching: query.trim() !== ""

    function evaluate(expr) {
        const q = String(expr).trim()
        if (q === "" || !/^[-+*/(). 0-9]+$/.test(q)) return ""
        try {
            const v = Function("return (" + q + ")")()
            if (typeof v !== "number" || !isFinite(v)) return ""
            return String(parseFloat(v.toFixed(8)))
        } catch (e) { return "" }
    }

    readonly property string calcValue: evaluate(query)
    // the inline hint on the Apps tab is only worth showing for something that
    // actually looks like a sum, or every bare number becomes a result
    readonly property string calc: /[-+*/]/.test(query) ? calcValue : ""

    readonly property var windowResults: {
        const q = query.trim().toLowerCase()
        const all = Compositor.windows
        if (q === "") return all
        return all.filter(w => (w.title || "").toLowerCase().indexOf(q) !== -1
                            || (w.appId || "").toLowerCase().indexOf(q) !== -1)
    }

    // Both list tabs render the same row, so they are normalised to one shape
    // here and share a single ListView below.
    readonly property var listModel: {
        if (tab === 0)
            return Apps.search(query).map(a => ({
                icon: a.icon, primary: a.name, secondary: a.comment, payload: a
            }))
        if (tab === 1)
            return windowResults.map(w => ({
                icon: Apps.iconFor(w.appId),
                primary: w.title !== "" ? w.title : w.appId,
                secondary: w.workspace !== "" ? w.appId + "  ·  workspace " + w.workspace : w.appId,
                payload: w
            }))
        return []
    }
    readonly property int count: listModel.length

    function open() {
        setQuery("")
        tab = 0
        active = true
        Compositor.refreshWindows()
        input.forceActiveFocus()
    }
    function close() { active = false; setQuery("") }
    function toggle() { active ? close() : open() }

    // Typing breaks a `text: root.query` binding for good, so the field is
    // driven one way and written through this instead.
    function setQuery(s) { input.text = s; index = 0 }

    function setTab(i) {
        tab = ((i % tabs.length) + tabs.length) % tabs.length
        index = 0
        if (tab === 1) Compositor.refreshWindows()
        input.forceActiveFocus()
    }

    function run() {
        if (tab === 2) {
            // fold the result back into the expression so it can be built on
            if (calcValue !== "") setQuery(calcValue)
            return
        }
        if (count === 0) return
        const item = listModel[Math.min(index, count - 1)].payload
        if (tab === 0) Apps.launch(item)
        else Compositor.focusWindow(item)
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

        // open straight onto a tab, for a keybind of its own
        function apps(): void { root.open(); root.setTab(0) }
        function windows(): void { root.open(); root.setTab(1) }
        function calculator(): void { root.open(); root.setTab(2) }
    }

    // click-away
    MouseArea {
        anchors.fill: parent
        onClicked: root.close()
    }

    Item {
        id: card
        // Whole pixels in both axes. A card on a fractional position is
        // resampled with a sub-pixel offset, which softens every pixel in it —
        // that, not the decode size, was what blurred the wallpaper.
        x: Math.round((parent.width - width) / 2)
        y: Math.round(parent.height * 0.18)
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
            // rounded, so the tile lands on the pixel grid rather than
            // straddling it — same reason as the card's x/y above
            readonly property int wallWidth:  root.hasWall ? Math.round(Math.min(wallMaxWidth, wallMaxHeight * wallAspect)) : 0
            readonly property int wallHeight: root.hasWall ? Math.round(wallWidth / wallAspect) : 0
            readonly property int paneWidth:  root.hasWall ? wallWidth + wallMargin * 2 : 0

            // Both axes are fixed, and identical across the three tabs. A
            // growing result list scrolls inside a static body rather than
            // resizing the launcher under the cursor. Only a wallpaper of a
            // different shape moves these, which is what the Behaviors are for.
            width: paneWidth + colWidth
            height: root.hasWall ? wallHeight + wallMargin * 2
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

                    // Decode at the size it is actually painted at, in device
                    // pixels. Decoding larger and letting the GPU shrink it is
                    // a bilinear downscale with no mipmap. Keyed off the
                    // constant cap rather than `width`, which would run back
                    // through implicitWidth into the tile's own size.
                    sourceSize.width: Math.round(shell.wallMaxWidth * Math.max(1, Screen.devicePixelRatio))
                    mipmap: true            // a tile narrower than the cap still shrinks
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
                    text: root.searching ? "󰍉" : root.tabs[root.tab].glyph
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
                        text: root.tabs[root.tab].hint
                        color: Theme.overlay
                        font: input.font
                        verticalAlignment: Text.AlignVCenter
                    }

                    Keys.onEscapePressed: root.close()
                    Keys.onReturnPressed: root.run()
                    Keys.onEnterPressed: root.run()
                    Keys.onDownPressed: root.index = Math.max(0, Math.min(root.index + 1, root.count - 1))
                    Keys.onUpPressed:   root.index = Math.max(root.index - 1, 0)
                    // Tab and the arrows never reach Keys.onTabPressed /
                    // Keys.onLeftPressed here: inside a TextInput, Qt's focus
                    // navigation claims Tab and the caret claims left/right
                    // before either handler runs, so both are taken here and
                    // marked handled.
                    //
                    // Left/right therefore move between tabs rather than the
                    // caret; Home/End and the mouse still place the caret.
                    Keys.onPressed: event => {
                        switch (event.key) {
                        case Qt.Key_Tab:
                        case Qt.Key_Right:
                            root.setTab(root.tab + 1); event.accepted = true; break
                        case Qt.Key_Backtab:
                        case Qt.Key_Left:
                            root.setTab(root.tab - 1); event.accepted = true; break
                        }
                    }
                }

                Rectangle {
                    anchors { left: parent.left; right: parent.right; bottom: parent.bottom
                              leftMargin: Theme.padding; rightMargin: Theme.padding }
                    height: 1
                    color: Theme.border
                }
            }

            // ---------- body ----------
            Item {
                id: body
                anchors.top: header.bottom
                x: shell.paneWidth
                width: shell.colWidth
                // whatever the card has left under the search field — static,
                // so a long result list scrolls instead of growing the launcher
                height: shell.height - header.height

                // ---------- tab strip ----------
                Row {
                    id: tabStrip
                    anchors { top: parent.top; left: parent.left; right: parent.right
                              topMargin: Theme.gap; leftMargin: Theme.gap; rightMargin: Theme.gap }
                    height: 36
                    spacing: Theme.gap

                    Repeater {
                        model: root.tabs

                        delegate: Rectangle {
                            required property var modelData
                            required property int index

                            width: (tabStrip.width - Theme.gap * (root.tabs.length - 1)) / root.tabs.length
                            height: tabStrip.height
                            radius: Theme.radiusSmall
                            color: index === root.tab ? Theme.selection
                                 : tabHover.hovered ? Theme.surface0 : "transparent"
                            border.width: Theme.borderWidth
                            border.color: index === root.tab ? Theme.selectionBorder : "transparent"

                            Behavior on color { ColorAnimation { duration: Theme.animFast } }

                            HoverHandler { id: tabHover }
                            TapHandler { onTapped: root.setTab(index) }

                            Row {
                                anchors.centerIn: parent
                                spacing: 8

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: modelData.glyph
                                    color: index === root.tab ? Theme.accent : Theme.overlay
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSizeLarge
                                }
                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: modelData.name
                                    color: index === root.tab ? Theme.text : Theme.overlay
                                    font.family: Theme.uiFont
                                    font.pixelSize: Theme.fontSize
                                }
                            }
                        }
                    }
                }

                Item {
                    id: content
                    anchors { top: tabStrip.bottom; left: parent.left; right: parent.right
                              bottom: parent.bottom; margins: Theme.gap }

                    // ---------- at rest, on the Apps tab: the time ----------
                    Column {
                        anchors.centerIn: parent
                        visible: root.tab === 0 && !root.searching
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

                    // ---------- calculator hint on the Apps tab ----------
                    Rectangle {
                        id: calcRow
                        visible: root.tab === 0 && root.searching && root.calc !== ""
                        anchors { top: parent.top; left: parent.left; right: parent.right }
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

                    // ---------- apps and windows share one list ----------
                    ListView {
                        id: list
                        visible: (root.tab === 0 && root.searching) || root.tab === 1
                        anchors {
                            top: calcRow.visible ? calcRow.bottom : parent.top
                            topMargin: calcRow.visible ? Theme.gap : 0
                            left: parent.left; right: parent.right; bottom: parent.bottom
                        }
                        clip: true
                        model: root.listModel
                        currentIndex: root.index
                        highlightMoveDuration: Theme.animFast
                        boundsBehavior: Flickable.StopAtBounds

                        onCurrentIndexChanged: positionViewAtIndex(currentIndex, ListView.Contain)

                        delegate: Rectangle {
                            required property var modelData
                            required property int index

                            width: list.width
                            height: 52
                            radius: Theme.radiusSmall
                            color: index === root.index ? Theme.selection
                                 : hover.hovered ? Theme.surface0 : "transparent"

                            Behavior on color { ColorAnimation { duration: Theme.animFast } }

                            HoverHandler { id: hover }
                            TapHandler { onTapped: { root.index = index; root.run() } }

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
                                text: root.tab === 1 ? "󰖯" : "󰣆"
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
                                    text: modelData.primary
                                    color: Theme.text
                                    elide: Text.ElideRight
                                    font.family: Theme.uiFont
                                    font.pixelSize: Theme.fontSize + 1
                                }
                                Text {
                                    width: parent.width
                                    visible: modelData.secondary !== ""
                                    text: modelData.secondary
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
                        visible: list.visible && root.count === 0 && !calcRow.visible
                        text: root.tab === 1 ? "no open windows" : "no matches"
                        color: Theme.overlay
                        font.family: Theme.uiFont
                        font.pixelSize: Theme.fontSize
                    }

                    // ---------- calculator ----------
                    Item {
                        visible: root.tab === 2
                        anchors.fill: parent

                        Text {
                            id: calcOut
                            anchors { top: parent.top; left: parent.left; right: parent.right
                                      rightMargin: Theme.padding }
                            height: 62
                            text: root.calcValue !== "" ? "= " + root.calcValue : ""
                            color: Theme.accent
                            font.family: Theme.uiFont
                            font.pixelSize: 40
                            font.weight: Font.Light
                            horizontalAlignment: Text.AlignRight
                            verticalAlignment: Text.AlignVCenter
                            elide: Text.ElideLeft
                        }

                        Grid {
                            id: pad
                            anchors { top: calcOut.bottom; topMargin: Theme.gap
                                      left: parent.left; right: parent.right; bottom: parent.bottom }
                            columns: 4
                            rows: 5
                            spacing: Theme.gap

                            Repeater {
                                model: [
                                    { label: "C", act: "clear" }, { label: "(",  ins: "(" },
                                    { label: ")", ins: ")" },     { label: "÷",  ins: "/" },
                                    { label: "7", ins: "7" },     { label: "8",  ins: "8" },
                                    { label: "9", ins: "9" },     { label: "×",  ins: "*" },
                                    { label: "4", ins: "4" },     { label: "5",  ins: "5" },
                                    { label: "6", ins: "6" },     { label: "−",  ins: "-" },
                                    { label: "1", ins: "1" },     { label: "2",  ins: "2" },
                                    { label: "3", ins: "3" },     { label: "+",  ins: "+" },
                                    { label: "0", ins: "0" },     { label: ".",  ins: "." },
                                    { label: "⌫", act: "back" },  { label: "=",  act: "equals" }
                                ]

                                delegate: Rectangle {
                                    required property var modelData

                                    readonly property bool isOp: modelData.act !== undefined
                                                              || ["/", "*", "-", "+"].indexOf(modelData.ins) !== -1

                                    width:  (pad.width  - pad.spacing * (pad.columns - 1)) / pad.columns
                                    height: (pad.height - pad.spacing * (pad.rows - 1)) / pad.rows
                                    radius: Theme.radiusSmall
                                    color: keyHover.hovered ? Theme.surface1
                                         : isOp ? Theme.surface0 : "transparent"
                                    border.width: Theme.borderWidth
                                    border.color: Theme.border

                                    Behavior on color { ColorAnimation { duration: Theme.animFast } }

                                    HoverHandler { id: keyHover }
                                    TapHandler {
                                        onTapped: {
                                            if (modelData.act === "clear") root.setQuery("")
                                            else if (modelData.act === "back") root.setQuery(input.text.slice(0, -1))
                                            else if (modelData.act === "equals") root.run()
                                            else root.setQuery(input.text + modelData.ins)
                                            input.forceActiveFocus()
                                        }
                                    }

                                    Text {
                                        anchors.centerIn: parent
                                        text: modelData.label
                                        color: isOp ? Theme.accent : Theme.text
                                        font.family: Theme.uiFont
                                        font.pixelSize: Theme.fontSizeLarge + 2
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
