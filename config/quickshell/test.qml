import QtQuick
import Quickshell
import Quickshell.Services.Notifications

ShellRoot {
    NotificationServer { id: srv }
    Timer {
        interval: 100; running: true; repeat: false
        onTriggered: {
            console.log("Keys: " + Object.keys(srv.trackedNotifications));
            console.log("Properties: ");
            for (var prop in srv.trackedNotifications) {
                console.log(prop + ": " + srv.trackedNotifications[prop]);
            }
            console.log("Notifications directly? " + srv.notifications);
            Qt.quit();
        }
    }
}
