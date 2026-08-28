//@ pragma UseQApplication

import Quickshell
import qs.modules.bar

// One bar per connected monitor; Variants keeps them in sync as outputs
// come and go.
ShellRoot {
    Variants {
        model: Quickshell.screens
        delegate: Bar {}
    }
}
