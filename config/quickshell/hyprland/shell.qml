//@ pragma UseQApplication

import Quickshell
import qs.modules.bar
import qs.modules.controlcenter
import qs.modules.launcher
import qs.modules.lock
import qs.modules.powermenu
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

    // ext-session-lock screen lock, engaged over IPC:
    //   qs -c hyprland ipc call lock lock
    Lock {}

    // session actions, replacing the rofi powermenu:
    //   qs -c hyprland ipc call powermenu toggle
    PowerMenu {}

    // control centre:
    //   qs -c hyprland ipc call controlcenter toggle
    ControlCenter {}
}
