//@ pragma UseQApplication

import Quickshell
import qs.modules.bar
import qs.modules.launcher

ShellRoot {
    // one island bar per connected monitor
    Variants {
        model: Quickshell.screens
        delegate: Bar {}
    }

    // single launcher, toggled over IPC:
    //   qs -p ~/.config/quickshell ipc call launcher toggle
    Launcher {}
}
