import QtQuick
import Quickshell
import qs

// Island bar: a transparent panel carrying three separate slabs. The panel
// itself reserves the strip; the islands float inside it.
PanelWindow {
    id: bar
    required property var modelData

    screen: modelData
    color: "transparent"

    anchors { top: true; left: true; right: true }
    implicitHeight: Theme.barHeight + Theme.barMargin * 2

    Item {
        id: strip
        anchors.fill: parent
        anchors.margins: Theme.barMargin

        // ---- left island ----
        Island {
            id: leftIsland
            anchors { left: parent.left; verticalCenter: parent.verticalCenter }
            Workspaces { screenName: bar.modelData.name }
        }

        // ---- centre island ----
        Island {
            id: centreIsland
            anchors.centerIn: parent

            // The centre island grows about the middle of the strip, so it runs
            // out of room against whichever side island is *wider* — it meets
            // that one first, and by symmetry the same amount is lost on both
            // sides. Budgeting against the real islands rather than a fixed
            // fraction of the screen is what keeps it off the clock as the tray
            // and the workspace list change width.
            readonly property real budget: strip.width
                - 2 * (Math.max(leftIsland.visible ? leftIsland.width : 0,
                                rightIsland.visible ? rightIsland.width : 0)
                       + Theme.islandGap)

            // Its own width is driven by the title's animation, not by a second
            // one on the slab, so the two edges move together.
            animateWidth: false

            MediaPlayer { id: media }
            ActiveWindow {
                maxWidth: centreIsland.budget
                    - Theme.padding * 2
                    - (media.visible ? media.width + Theme.gap : 0)
            }
        }

        // ---- right island ----
        Island {
            id: rightIsland
            anchors { right: parent.right; verticalCenter: parent.verticalCenter }
            Tray {}
            Backlight {}
            Audio {}
            Network {}
            Battery {}
            Clock {}
        }
    }
}
