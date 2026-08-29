import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Notifications
import qs

// The org.freedesktop.Notifications daemon plus its on-screen stack.
// Sits below the bar on one screen; duplicating a toast across monitors is
// noise, not redundancy.
Scope {
    id: root

    property var targetScreen: Quickshell.screens.length > 0 ? Quickshell.screens[0] : null

    NotificationServer {
        id: server
        imageSupported: true
        actionsSupported: true
        bodyMarkupSupported: true
        actionIconsSupported: false
        persistenceSupported: true

        onNotification: notification => {
            // keep it alive until we dismiss it ourselves
            notification.tracked = true
        }
    }

    PanelWindow {
        id: layer
        screen: root.targetScreen
        visible: server.trackedNotifications.values.length > 0

        color: "transparent"
        anchors { top: true; right: true }
        margins {
            top: Theme.barHeight + Theme.barMargin * 2 + Theme.islandGap
            right: Theme.barMargin
        }

        implicitWidth: 400
        implicitHeight: Math.max(1, list.contentHeight)

        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "qs-notifications"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        exclusionMode: ExclusionMode.Ignore

        ListView {
            id: list
            anchors.fill: parent
            spacing: Theme.islandGap
            interactive: false
            model: server.trackedNotifications

            delegate: NotificationCard {
                required property var modelData
                width: list.width
                notif: modelData
                onClosed: modelData.dismiss()
            }

            // one motion language: slide in from the edge, melt back out
            add: Transition {
                NumberAnimation { property: "opacity"; from: 0; to: 1; duration: Theme.animNormal }
                NumberAnimation { property: "x"; from: 60; to: 0; duration: Theme.animNormal; easing.type: Theme.easing }
            }
            remove: Transition {
                NumberAnimation { property: "opacity"; to: 0; duration: Theme.animFast }
                NumberAnimation { property: "x"; to: 60; duration: Theme.animFast; easing.type: Theme.easing }
            }
            displaced: Transition {
                NumberAnimation { properties: "x,y"; duration: Theme.animNormal; easing.type: Theme.easing }
            }
        }
    }
}
