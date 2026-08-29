//@ pragma UseQApplication

import Quickshell
import qs.modules.bar
import qs.modules.launcher
import qs.modules.notifications

ShellRoot {
    // one island bar per connected monitor
    Variants {
        model: Quickshell.screens
        delegate: Bar {}
    }

    // single launcher, toggled over IPC:
    //   qs -c hyprland ipc call launcher toggle
    Launcher {}

    // org.freedesktop.Notifications daemon + toast stack
    Notifications {}
}
